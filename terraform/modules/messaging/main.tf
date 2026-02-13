resource "aws_sqs_queue" "ingestion_dlq" {
  name                      = "${var.resource_prefix}-ingestion-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "ingestion_queue" {
  name                       = "${var.resource_prefix}-ingestion-queue"
  visibility_timeout_seconds = var.visibility_timeout
  message_retention_seconds  = var.message_retention

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.ingestion_dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "ingestion_dlq_allow" {
  queue_url = aws_sqs_queue.ingestion_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.ingestion_queue.arn]
  })
}
