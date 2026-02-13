variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "region" {
  description = "AWS region name"
  type        = string
}

variable "account_id" {
  description = "AWS account ID"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS ingestion queue"
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB ingestion state table"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 ingestion data bucket"
  type        = string
}
