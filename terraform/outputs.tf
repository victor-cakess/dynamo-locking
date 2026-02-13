output "sqs_queue_url" {
  description = "URL of the ingestion SQS queue"
  value       = module.messaging.queue_url
}

output "sqs_dlq_url" {
  description = "URL of the dead-letter queue"
  value       = module.messaging.dlq_url
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB ingestion state table"
  value       = module.storage.dynamodb_table_name
}

output "s3_bucket_name" {
  description = "Name of the ingestion data S3 bucket"
  value       = module.storage.s3_bucket_name
}

output "lambda_function_arn" {
  description = "ARN of the deduplication processor Lambda function"
  value       = module.compute.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the deduplication processor Lambda function"
  value       = module.compute.lambda_function_name
}
