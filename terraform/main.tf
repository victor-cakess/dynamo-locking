terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }

  backend "s3" {
    bucket       = "dynamo-locking-terraform-state"
    key          = "state/terraform.tfstate"
    region       = "sa-east-1"
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
      Application = "deduplication-engine"
    }
  }
}

locals {
  resource_prefix = "${var.project_name}-dev"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# --- Modules ---

module "storage" {
  source          = "./modules/storage"
  resource_prefix = local.resource_prefix
  ttl_attribute   = var.dynamodb_ttl_attribute
}

module "messaging" {
  source             = "./modules/messaging"
  resource_prefix    = local.resource_prefix
  visibility_timeout = var.sqs_visibility_timeout
  message_retention  = var.sqs_message_retention
  max_receive_count  = var.sqs_max_receive_count
}

module "iam" {
  source             = "./modules/iam"
  resource_prefix    = local.resource_prefix
  region             = data.aws_region.current.name
  account_id         = data.aws_caller_identity.current.account_id
  sqs_queue_arn      = module.messaging.queue_arn
  dynamodb_table_arn = module.storage.dynamodb_table_arn
  s3_bucket_arn      = module.storage.s3_bucket_arn
}

module "compute" {
  source              = "./modules/compute"
  resource_prefix     = local.resource_prefix
  lambda_runtime      = var.lambda_runtime
  lambda_timeout      = var.lambda_timeout
  lambda_memory_size  = var.lambda_memory_size
  lambda_batch_size   = var.lambda_batch_size
  lambda_role_arn     = module.iam.lambda_role_arn
  sqs_queue_arn       = module.messaging.queue_arn
  dynamodb_table_name = module.storage.dynamodb_table_name
  s3_bucket_name      = module.storage.s3_bucket_name
  lambda_source_file = "${path.root}/../local-lambda/handler.py"
}
