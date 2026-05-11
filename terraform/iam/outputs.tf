output "lambda_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}

output "step_function_role_arn" {
  value = aws_iam_role.step_function_role.arn
}
