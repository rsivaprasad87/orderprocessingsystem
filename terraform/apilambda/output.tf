output "api_handler_invoke_arn" {
  value = aws_lambda_function.api_handler.arn
}

output "api_handler_name" {
  value = aws_lambda_function.api_handler.function_name
}