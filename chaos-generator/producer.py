import boto3
import json
import time
from concurrent.futures import ThreadPoolExecutor

# Initialize the SQS client.
sqs = boto3.client('sqs', region_name='sa-east-1')
queue_url = 'https://sqs.sa-east-1.amazonaws.com/503561429803/dynamo-locking-dev-ingestion-queue'

def send_reading(event_id, voltage):
    # We mock an ENTSO-E grid stress reading.
    payload = {
        'event_id': event_id,
        'sensor': 'substation_alpha',
        'voltage': voltage,
        'timestamp': time.time()
    }
    
    response = sqs.send_message(
        QueueUrl=queue_url,
        MessageBody=json.dumps(payload)
    )
    return response['MessageId']

def simulate_chaos():
    # We intentionally use the same event_id to create a race condition.
    duplicate_event_id = "grid_stress_999"
    
    print("Initiating thundering herd test...")
    with ThreadPoolExecutor(max_workers=50) as executor:
        # Submit 50 identical tasks to the thread pool.
        futures = [executor.submit(send_reading, duplicate_event_id, 245.5) for _ in range(50)]
        
        for future in futures:
            try:
                future.result()
            except Exception as e:
                print(f"Failed to send: {e}")
                
    print("Chaos simulation complete.")

if __name__ == "__main__":
    simulate_chaos()