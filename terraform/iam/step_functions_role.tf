resource "aws_iam_role" "step_function_role" {
  name = "${var.project_name}-${terraform.workspace}-step-function-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = terraform.workspace
  }
}

resource "aws_iam_policy" "step_function_policy" {
  name = "${var.project_name}-${terraform.workspace}-step-function-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "step_attach" {
  role       = aws_iam_role.step_function_role.name
  policy_arn = aws_iam_policy.step_function_policy.arn
}