variable "resource_prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "visibility_timeout" {
  description = "SQS visibility timeout in seconds"
  type        = number
}

variable "message_retention" {
  description = "SQS message retention period in seconds"
  type        = number
}

variable "max_receive_count" {
  description = "Maximum receive count before message is sent to DLQ"
  type        = number
}
