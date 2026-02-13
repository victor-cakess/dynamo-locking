# --- DynamoDB ---

resource "aws_dynamodb_table" "ingestion_state" {
  name         = "${var.resource_prefix}-ingestion-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  ttl {
    attribute_name = var.ttl_attribute
    enabled        = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# --- S3 ---

resource "aws_s3_bucket" "ingestion_data" {
  bucket = "${var.resource_prefix}-ingestion-data"
}

resource "aws_s3_bucket_versioning" "ingestion_data" {
  bucket = aws_s3_bucket.ingestion_data.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "ingestion_data" {
  bucket = aws_s3_bucket.ingestion_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ingestion_data" {
  bucket = aws_s3_bucket.ingestion_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}
