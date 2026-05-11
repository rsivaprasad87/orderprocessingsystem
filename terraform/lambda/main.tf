resource "aws_lambda_function" "this" {
  for_each = var.lambdas

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = var.lambda_role_arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  filename      = each.value.filename
  timeout       = each.value.timeout

  source_code_hash = filebase64sha256(each.value.filename)
  environment {
    variables = {
      ORDERS_TABLE   = var.orders_table_name
      ARCHIVE_BUCKET = var.archive_bucket_name
    }
  }

  tags = {
    Environment = var.environment
  }
}

