variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
}

variable "lambda_batch_size" {
  description = "Number of SQS messages per Lambda invocation"
  type        = number
}

variable "lambda_role_arn" {
  description = "ARN of the IAM role for Lambda execution"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN of the SQS ingestion queue"
  type        = string
}

variable "dynamodb_table_name" {
  description = "Name of the DynamoDB ingestion state table"
  type        = string
}

variable "s3_bucket_name" {
  description = "Name of the S3 ingestion data bucket"
  type        = string
}
