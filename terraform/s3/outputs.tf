output "archive_bucket_name" {
  value = aws_s3_bucket.archive.bucket
}

output "archive_bucket_arn" {
  value = aws_s3_bucket.archive.arn
}