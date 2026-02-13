# Dynamo locking — serverless distributed deduplication engine

## What this project does

This project implements a serverless pipeline on AWS designed to test and demonstrate distributed deduplication using DynamoDB as a state store. A chaos generator script simulates a "thundering herd" scenario by flooding an SQS queue with 50 concurrent identical messages, forcing the system to handle deduplication under race conditions.

## Architecture overview

The data flow is:

```
producer.py  ──►  SQS queue  ──►  Lambda (batch of 10)  ──►  DynamoDB (state)
                     │                                    ──►  S3 (data lake)
                     ▼
                  DLQ (after 3 failed attempts)
```

- **SQS** acts as the ingestion buffer, decoupling the producer from the consumer.
- **Lambda** consumes messages in batches of 10 with partial batch failure reporting enabled.
- **DynamoDB** stores deduplication state using a composite key (`pk`/`sk`) with TTL for automatic cleanup.
- **S3** serves as the data lake for persisted results.
- A **dead-letter queue** catches messages that fail processing after 3 retries.

## Current status

The infrastructure is fully provisioned via Terraform. The Lambda function currently runs a **placeholder handler** that only logs incoming messages — it does not yet write to DynamoDB or S3. The next step is implementing the actual deduplication logic in the Lambda handler.

## Project structure

```
dynamo-locking/
├── chaos-generator/
│   └── producer.py                          # Thundering herd simulator (50 concurrent SQS messages)
├── scripts/
│   └── bootstrap-backend.sh                 # Creates the S3 bucket for Terraform state
├── terraform/
│   ├── main.tf                              # Provider, S3 backend, locals, module calls
│   ├── variables.tf                         # Root-level input variables
│   ├── outputs.tf                           # Proxied outputs from all modules
│   ├── .terraform.lock.hcl                  # Provider version lock file
│   └── modules/
│       ├── storage/                         # DynamoDB table + S3 bucket
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── messaging/                       # SQS queue + dead-letter queue
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       ├── compute/                         # Lambda function + SQS event source mapping
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   └── outputs.tf
│       └── iam/                             # Lambda execution role + least-privilege policies
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
└── .gitignore
```

## What was built

### Bootstrap script (`scripts/bootstrap-backend.sh`)

An idempotent bash script that creates the S3 bucket used for Terraform remote state. It:
- Creates the bucket `dynamo-locking-terraform-state` in `sa-east-1`
- Enables versioning
- Blocks all public access
- Enables AES256 server-side encryption
- Skips creation if the bucket already exists

### Terraform backend (`terraform/main.tf`)

The Terraform configuration uses an S3 backend with `use_lockfile = true`, which is the native S3 locking mechanism available since Terraform 1.10. This eliminates the need for a DynamoDB table for state locking.

Common tags (`Project`, `Environment`, `ManagedBy`, `Application`) are applied to all resources via the provider's `default_tags` block.

### Storage module (`terraform/modules/storage/`)

Contains two resources:

**DynamoDB table** (`dynamo-locking-dev-ingestion-state`):
- Billing mode: pay per request (on-demand)
- Partition key: `pk` (string)
- Sort key: `sk` (string)
- TTL enabled on the `ttl` attribute
- Point-in-time recovery enabled

**S3 bucket** (`dynamo-locking-dev-ingestion-data`):
- Versioning enabled
- All public access blocked
- Server-side encryption with KMS and bucket keys

### Messaging module (`terraform/modules/messaging/`)

**Main queue** (`dynamo-locking-dev-ingestion-queue`):
- Visibility timeout: 180 seconds (6x the Lambda timeout, per AWS best practice)
- Message retention: 24 hours
- Redrive policy sends failed messages to the DLQ after 3 receive attempts

**Dead-letter queue** (`dynamo-locking-dev-ingestion-dlq`):
- Message retention: 14 days (maximum)
- Redrive allow policy restricts which queues can send to it

### Compute module (`terraform/modules/compute/`)

**Lambda function** (`dynamo-locking-dev-dedup-processor`):
- Runtime: Python 3.12
- Timeout: 30 seconds
- Memory: 128 MB
- X-Ray tracing enabled
- Environment variables pass the DynamoDB table name and S3 bucket name

**SQS event source mapping**:
- Batch size: 10
- Batching window: 5 seconds
- Partial batch failure reporting enabled via `ReportBatchItemFailures`

The function code is a placeholder generated inline by the `archive` provider — no source file on disk. It logs each message's `event_id` and `sensor` fields and returns a success response.

### IAM module (`terraform/modules/iam/`)

A single Lambda execution role with four scoped inline policies:

| Policy | Actions | Resource scope |
|---|---|---|
| CloudWatch logs | `CreateLogGroup`, `CreateLogStream`, `PutLogEvents` | The Lambda's specific log group ARN |
| SQS | `ReceiveMessage`, `DeleteMessage`, `GetQueueAttributes` | The ingestion queue ARN |
| DynamoDB | `PutItem`, `UpdateItem`, `GetItem` | The ingestion state table ARN |
| S3 | `PutObject` | Objects in the ingestion data bucket |

All policies use `aws_iam_policy_document` data sources for type safety and are scoped to exact resource ARNs — no wildcards.

### Chaos generator (`chaos-generator/producer.py`)

A Python script that simulates a thundering herd attack:
- Uses `ThreadPoolExecutor` with 50 worker threads
- Sends 50 messages with the same `event_id` (`grid_stress_999`) to create intentional duplicates
- Each message contains a mock ENTSO-E grid stress reading with sensor, voltage, and timestamp fields

## How to deploy

```bash
# 1. Bootstrap the state bucket (one-time)
bash scripts/bootstrap-backend.sh

# 2. Initialize Terraform
cd terraform
terraform init

# 3. Validate and preview
terraform validate
terraform plan

# 4. Apply
terraform apply

# 5. Grab the queue URL
terraform output sqs_queue_url
```

## How to run the chaos test

Update the `queue_url` in `chaos-generator/producer.py` with the output from step 5 above, then:

```bash
python chaos-generator/producer.py
```

Check the Lambda's CloudWatch logs to see the processed messages.

## How to tear down

```bash
cd terraform
terraform destroy
```

## What's next

- Implement the actual deduplication logic in the Lambda handler (conditional writes to DynamoDB, storage to S3)
- Update `producer.py` to read the queue URL from Terraform output or environment variables instead of hardcoding it
