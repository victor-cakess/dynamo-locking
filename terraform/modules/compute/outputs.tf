output "lambda_function_arn" {
  description = "ARN of the deduplication processor Lambda function"
  value       = aws_lambda_function.deduplication_processor.arn
}

output "lambda_function_name" {
  description = "Name of the deduplication processor Lambda function"
  value       = aws_lambda_function.deduplication_processor.function_name
}
