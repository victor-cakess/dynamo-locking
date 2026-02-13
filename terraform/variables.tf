variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "sa-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resource names"
  type        = string
  default     = "dynamo-locking"
}

variable "lambda_runtime" {
  description = "Lambda function runtime"
  type        = string
  default     = "python3.12"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 30
}

variable "lambda_memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 128
}

variable "sqs_visibility_timeout" {
  description = "SQS visibility timeout in seconds (should be >= 6x Lambda timeout)"
  type        = number
  default     = 180
}

variable "sqs_message_retention" {
  description = "SQS message retention period in seconds"
  type        = number
  default     = 86400
}

variable "sqs_max_receive_count" {
  description = "Maximum receive count before message is sent to DLQ"
  type        = number
  default     = 3
}

variable "lambda_batch_size" {
  description = "Number of SQS messages per Lambda invocation"
  type        = number
  default     = 10
}

variable "dynamodb_ttl_attribute" {
  description = "DynamoDB TTL attribute name"
  type        = string
  default     = "ttl"
}
