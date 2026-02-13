output "queue_url" {
  description = "URL of the ingestion SQS queue"
  value       = aws_sqs_queue.ingestion_queue.url
}

output "queue_arn" {
  description = "ARN of the ingestion SQS queue"
  value       = aws_sqs_queue.ingestion_queue.arn
}

output "dlq_url" {
  description = "URL of the dead-letter queue"
  value       = aws_sqs_queue.ingestion_dlq.url
}

output "dlq_arn" {
  description = "ARN of the dead-letter queue"
  value       = aws_sqs_queue.ingestion_dlq.arn
}
