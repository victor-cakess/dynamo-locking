# --- Trust Policy ---

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_execution" {
  name               = "${var.resource_prefix}-lambda-execution-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# --- CloudWatch Logs Policy ---

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = [
      "arn:aws:logs:${var.region}:${var.account_id}:log-group:/aws/lambda/${var.resource_prefix}-dedup-processor:*"
    ]
  }
}

resource "aws_iam_role_policy" "lambda_logging" {
  name   = "${var.resource_prefix}-lambda-logging"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_logging.json
}

# --- SQS Policy ---

data "aws_iam_policy_document" "lambda_sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [
      var.sqs_queue_arn,
    ]
  }
}

resource "aws_iam_role_policy" "lambda_sqs" {
  name   = "${var.resource_prefix}-lambda-sqs"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_sqs.json
}

# --- DynamoDB Policy ---

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
      "dynamodb:GetItem",
    ]
    resources = [
      var.dynamodb_table_arn,
    ]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.resource_prefix}-lambda-dynamodb"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

# --- S3 Policy ---

data "aws_iam_policy_document" "lambda_s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
    ]
    resources = [
      "${var.s3_bucket_arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_s3" {
  name   = "${var.resource_prefix}-lambda-s3"
  role   = aws_iam_role.lambda_execution.id
  policy = data.aws_iam_policy_document.lambda_s3.json
}
