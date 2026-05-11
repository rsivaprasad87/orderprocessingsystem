resource "aws_s3_bucket" "tf_state" {
  bucket = local.archive_bucket_name  # must be globally unique
   tags = {
    Purpose = "order-archive"
    Env     = terraform.workspace
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls   = true
  block_public_policy = true
  ignore_public_acls  = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "tf_lock" {
  name         = local.orders_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Service = "order-processing"
    Env     = terraform.workspace
  }
}

locals {
  environment         = terraform.workspace
  archive_bucket_name = "order-process-state-${local.environment}-${data.aws_caller_identity.current.account_id}"
  orders_table_name   = "order-process-state-${local.environment}"
}