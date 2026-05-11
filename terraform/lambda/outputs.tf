output "lambda_arns" {
  value = {
    for name, lambda in aws_lambda_function.this :
    name => lambda.arn
  }
}
