resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprints — both are valid; AWS validates against its own CA in newer regions
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd"
  ]
}

resource "aws_iam_role" "github_actions" {
  name = "github-actions-terraform-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          # Restrict to your repo only — prevents other GitHub repos from assuming this role
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
        }
      }
    }]
  })
}

resource "aws_iam_policy" "github_actions" {
  name        = "github-actions-terraform-policy"
  description = "Scoped permissions for GitHub Actions to manage order processing infrastructure via Terraform"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "CallerIdentity"
        Effect   = "Allow"
        Action   = ["sts:GetCallerIdentity"]
        Resource = "*"
      },
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::order-process-state-dev-*",
          "arn:aws:s3:::order-process-state-dev-*/*"
        ]
      },
      {
        Sid    = "TerraformStateLock"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:ap-south-1:*:table/order-process-state-*"
      },
      {
        Sid    = "ArchiveBucket"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketObjectLockConfiguration",
          "s3:GetBucketCORS",
          "s3:GetBucketWebsite",
          "s3:GetBucketLogging",
          "s3:GetBucketNotification",
          "s3:GetLifecycleConfiguration",
          "s3:GetReplicationConfiguration",
          "s3:GetAccelerateConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:PutBucketOwnershipControls"
        ]
        Resource = "arn:aws:s3:::order-archive-*"
      },
      {
        Sid    = "OrdersTable"
        Effect = "Allow"
        Action = [
          "dynamodb:CreateTable",
          "dynamodb:DeleteTable",
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:UpdateContinuousBackups",
          "dynamodb:DescribeTimeToLive",
          "dynamodb:ListTagsOfResource",
          "dynamodb:TagResource",
          "dynamodb:UntagResource",
          "dynamodb:UpdateTable"
        ]
        Resource = "arn:aws:dynamodb:ap-south-1:*:table/orders-table-*"
      },
      {
        Sid    = "LambdaFunctions"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetPolicy",
          "lambda:ListVersionsByFunction",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:GetFunctionCodeSigningConfig",
          "lambda:PutFunctionEventInvokeConfig"
        ]
        Resource = [
          "arn:aws:lambda:ap-south-1:*:function:order-processing-*",
          "arn:aws:lambda:ap-south-1:*:function:order-api-handler-*"
        ]
      },
      {
        Sid    = "IAMRoles"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRolePolicy",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/lambda-execution-role-*",
          "arn:aws:iam::*:role/lambda-api-role-*",
          "arn:aws:iam::*:role/order-processing-*"
        ]
      },
      {
        Sid    = "IAMPolicies"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::*:policy/lambda-execution-policy-*",
          "arn:aws:iam::*:policy/order-processing-*"
        ]
      },
      {
        Sid    = "StepFunctions"
        Effect = "Allow"
        Action = [
          "states:CreateStateMachine",
          "states:DeleteStateMachine",
          "states:DescribeStateMachine",
          "states:UpdateStateMachine",
          "states:ListTagsForResource",
          "states:ListStateMachineVersions",
          "states:TagResource",
          "states:UntagResource"
        ]
        Resource = "arn:aws:states:ap-south-1:*:stateMachine:order-processing-*"
      },
      {
        # API Gateway v2 resource ARNs aren't predictable before creation, so scoped to region
        Sid    = "APIGateway"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:PATCH",
          "apigateway:DELETE"
        ]
        Resource = "arn:aws:apigateway:ap-south-1::/*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:ListTagsLogGroup",
          "logs:ListTagsForResource",
          "logs:PutRetentionPolicy",
          "logs:TagResource",
          "logs:UntagResource"
        ]
        Resource = [
          "arn:aws:logs:ap-south-1:*:log-group:/aws/lambda/order-*",
          "arn:aws:logs:ap-south-1:*:log-group:/aws/lambda/order-*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions.arn
}
