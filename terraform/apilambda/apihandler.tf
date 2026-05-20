
resource "aws_lambda_function" "api_handler" {
  function_name = "order-api-handler-${var.environment}"
  role          = aws_iam_role.lambda_api_role.arn
  handler       = "start_order.lambda_handler"
  runtime       = "python3.11"

  filename = "${path.module}/start_order.zip"
  source_code_hash = sha256(join("", [
    for f in sort(fileset("${path.root}/lambda_src/start_order", "**")) :
    filesha256("${path.root}/lambda_src/start_order/${f}")
  ]))

  environment {
    variables = {
      STATE_MACHINE_ARN = var.state_machine_arn
    }
  }
}
resource "aws_iam_role" "lambda_api_role" {
  name = "lambda-api-role-${terraform.workspace}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}
# resource "aws_iam_role_policy" "lambda_stepfn_policy" {
#   role = aws_iam_role.lambda_api_role.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Effect = "Allow",
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }
resource "aws_iam_role_policy" "lambda_stepfn_policy" {
  role = aws_iam_role.lambda_api_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "states:StartExecution"
        ]
        Resource = var.state_machine_arn
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}