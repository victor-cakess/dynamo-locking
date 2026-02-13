output "dynamodb_table_name" {
  description = "Name of the DynamoDB ingestion state table"
  value       = aws_dynamodb_table.ingestion_state.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB ingestion state table"
  value       = aws_dynamodb_table.ingestion_state.arn
}

output "s3_bucket_name" {
  description = "Name of the ingestion data S3 bucket"
  value       = aws_s3_bucket.ingestion_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the ingestion data S3 bucket"
  value       = aws_s3_bucket.ingestion_data.arn
}
