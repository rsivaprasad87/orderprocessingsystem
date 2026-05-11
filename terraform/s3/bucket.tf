resource "aws_s3_bucket" "archive" {
  bucket = var.bucket_name

  tags = {
    Purpose = "order-archive"
    Env     = terraform.workspace
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.archive.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = aws_s3_bucket.archive.id

  versioning_configuration {
    status = "Enabled"
  }
}