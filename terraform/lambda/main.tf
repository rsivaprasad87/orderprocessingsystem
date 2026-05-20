resource "aws_lambda_function" "this" {
  for_each = var.lambdas

  function_name = "${var.project_name}-${var.environment}-${each.key}"
  role          = var.lambda_role_arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  filename      = each.value.filename
  timeout       = each.value.timeout

  source_code_hash = sha256(join("", [
    for f in sort(fileset("${path.root}/lambda_src/${each.key}", "**")) :
    filesha256("${path.root}/lambda_src/${each.key}/${f}")
  ]))
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

