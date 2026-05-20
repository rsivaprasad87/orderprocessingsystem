output "github_actions_role_arn" {
  description = "Add this value as the AWS_ROLE_ARN secret in your GitHub repository settings"
  value       = aws_iam_role.github_actions.arn
}
