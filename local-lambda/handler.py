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

# Environment variables injected by Terraform
TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
BUCKET_NAME = os.environ['S3_BUCKET_NAME']
table = dynamodb.Table(TABLE_NAME)

def handler(event, context):
    """
    Idempotent Event Processor.
    Ensures exactly-once processing using DynamoDB Conditional Writes.
    """
    batch_item_failures = []
    
    for record in event.get("Records", []):
        try:
            message_id = record['messageId']
            body = json.loads(record["body"])
            event_id = body.get("event_id")
            sensor_id = body.get("sensor")
            
            current_time = int(time.time())
            # TTL: 30 seconds
            ttl_time = current_time + 30

            # --- 1. THE GATEKEEPER (Optimistic Locking) ---
            try:
                # Attempt to write lock. Fails if 'pk' already exists.
                table.put_item(
                    Item={
                        'pk': f"EVENT#{event_id}",
                        'sk': 'METADATA',
                        'status': 'PROCESSING',
                        'sensor': sensor_id,
                        'timestamp': current_time,
                        'ttl': ttl_time 
                    },
                    ConditionExpression='attribute_not_exists(pk)'
                )
                logger.info(f"Lock acquired for {event_id}. Processing...")
                
            except ClientError as e:
                if e.response['Error']['Code'] == 'ConditionalCheckFailedException':
                    logger.warning(f"DUPLICATE PREVENTED: {event_id} already exists.")
                    # We return SUCCESS to SQS so it deletes this duplicate message.
                    continue 
                else:
                    raise e

            if event_id == "zombie_test_001":
                            logger.error("Simulating crash")
                            raise Exception("OOM")

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
            # Mark as COMPLETED. 
            table.update_item(
                Key={'pk': f"EVENT#{event_id}", 'sk': 'METADATA'},
                UpdateExpression="SET #s = :status",
                ExpressionAttributeNames={'#s': 'status'},
                ExpressionAttributeValues={':status': 'COMPLETED'}
            )

        except Exception as e:
            logger.error(f"FAILED to process message {message_id}: {str(e)}")
            # Return failure to SQS so it can retry LATER
            batch_item_failures.append({"itemIdentifier": message_id})

    return {"batchItemFailures": batch_item_failures}