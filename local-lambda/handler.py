import boto3
import json
import logging
import os
import time
from botocore.exceptions import ClientError

# Initialize clients outside handler
dynamodb = boto3.resource('dynamodb')
s3 = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Environment variables
TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
BUCKET_NAME = os.environ['S3_BUCKET_NAME']
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Idempotent Event Processor with Lease Expiration.
    """
    batch_item_failures = []
    
    for record in event.get("Records", []):
        try:
            message_id = record['messageId']
            body = json.loads(record["body"])
            event_id = body.get("event_id")
            sensor_id = body.get("sensor")
            
            current_time = int(time.time())
            
            # CONFIGURATION:
            # Lease Duration: 2 minutes (How long we trust a lock)
            # TTL: 24 hours (When DynamoDB should delete the record to save money)
            lease_seconds = 30
            stale_cutoff = current_time - lease_seconds
            ttl_time = current_time + 86400 

            # --- 1. THE GATEKEEPER ---
            try:
                table.put_item(
                    Item={
                        'pk': f"EVENT#{event_id}",
                        'sk': 'METADATA',
                        'status': 'PROCESSING',
                        'sensor': sensor_id,
                        'timestamp': current_time, # Critical for the check
                        'ttl': ttl_time
                    },
                    # THE FIX: 
                    # "Write if it doesn't exist OR if the existing one is older than 30 seconds"
                    ConditionExpression='attribute_not_exists(pk) OR #ts < :stale_limit',
                    ExpressionAttributeNames={'#ts': 'timestamp'},
                    ExpressionAttributeValues={':stale_limit': stale_cutoff}
                )
                logger.info(f"Lock acquired for {event_id}. Processing...")
                
            except ClientError as e:
                if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                    logger.warning(f"DUPLICATE PREVENTED: {event_id} is locked and active.")
                    continue 
                else:
                    raise e

            # --- 2. Write to S3 ---
            s3_key = f"raw/{event_id}.json"
            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=s3_key,
                Body=json.dumps(body),
                ContentType='application/json'
            )
            logger.info(f"Payload persisted to s3://{BUCKET_NAME}/{s3_key}")

            # --- 3. STATE UPDATE ---
            table.update_item(
                Key={'pk': f"EVENT#{event_id}", 'sk': 'METADATA'},
                UpdateExpression="SET #s = :status",
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':status': 'COMPLETED'}
            )

        except Exception as e:
            logger.error(f"FAILED to process message {message_id}: {str(e)}")
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}