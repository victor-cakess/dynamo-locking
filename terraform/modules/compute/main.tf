data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.build/lambda_placeholder.zip"

  source {
    content  = <<-PYTHON
      import json
      import logging

      logger = logging.getLogger()
      logger.setLevel(logging.INFO)

      def handler(event, context):
          """Placeholder Lambda handler for deduplication engine."""
          for record in event.get("Records", []):
              body = json.loads(record["body"])
              logger.info("Processing event_id=%s sensor=%s", body.get("event_id"), body.get("sensor"))
          return {"statusCode": 200, "processedRecords": len(event.get("Records", []))}
    PYTHON
    filename = "handler.py"
  }
}

resource "aws_lambda_function" "deduplication_processor" {
  function_name    = "${var.resource_prefix}-dedup-processor"
  role             = var.lambda_role_arn
  handler          = "handler.handler"
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  filename         = data.archive_file.lambda_placeholder.output_path
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
      S3_BUCKET_NAME      = var.s3_bucket_name
      ENVIRONMENT         = "dev"
    }
  }

  tracing_config {
    mode = "Active"
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn                   = var.sqs_queue_arn
  function_name                      = aws_lambda_function.deduplication_processor.arn
  batch_size                         = var.lambda_batch_size
  maximum_batching_window_in_seconds = 5
  enabled                            = true

  function_response_types = ["ReportBatchItemFailures"]
}
