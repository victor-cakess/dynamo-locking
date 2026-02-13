data "archive_file" "lambda_package" {
  type        = "zip"
  source_file = var.lambda_source_file  
  output_path = "${path.module}/.build/lambda_dedup.zip"
}

resource "aws_lambda_function" "deduplication_processor" {
  function_name    = "${var.resource_prefix}-dedup-processor"
  role             = var.lambda_role_arn
  handler          = "handler.handler" # This remains the same because the file inside the zip is still handler.py
  runtime          = var.lambda_runtime
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  # --- UPDATED REFERENCES ---
  filename         = data.archive_file.lambda_package.output_path
  source_code_hash = data.archive_file.lambda_package.output_base64sha256
  # --------------------------

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
