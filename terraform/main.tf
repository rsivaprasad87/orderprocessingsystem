module "dynamodb" {
  source     = "./dynamodb"
  table_name = local.orders_table_name
}

module "s3" {
  source      = "./s3"
  bucket_name = local.archive_bucket_name
}

module "iam" {
  source              = "./iam"
  orders_table_name   = module.dynamodb.orders_table_name
  archive_bucket_name = module.s3.archive_bucket_name
  project_name        = var.project_name_prefix
}

module "lambda" {
  source              = "./lambda"
  project_name        = var.project_name_prefix
  orders_table_name   = local.orders_table_name
  archive_bucket_name = local.archive_bucket_name
  environment         = terraform.workspace
  lambda_role_arn     = module.iam.lambda_role_arn
  lambdas = {
    validate_order = {
      handler  = "handler.handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/validate_order.zip"
      timeout  = 10
    }

    process_payment = {
      handler  = "handler.lambda_handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/process_payment.zip"
      timeout  = 15
    }

    reserve_inventory = {
      handler  = "handler.lambda_handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/reserve_inventory.zip"
      timeout  = 10
    }

    archive_order = {
      handler  = "handler.lambda_handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/archive_order.zip"
      timeout  = 5
    }

    finalize_order = {
      handler  = "handler.lambda_handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/finalize_order.zip"
      timeout  = 15
    }

    release_inventory = {
      handler  = "handler.lambda_handler"
      runtime  = "python3.11"
      filename = "${path.root}/lambda/release_inventory.zip"
      timeout  = 10
    }

  }
}

module "stepfunctions" {
  source                 = "./stepfunctions"
  project_name           = var.project_name_prefix
  environment            = terraform.workspace
  step_function_role_arn = module.iam.step_function_role_arn
  lambda_arns            = module.lambda.lambda_arns
}

module "apihandler" {
  source            = "./apilambda"
  state_machine_arn = module.stepfunctions.state_machine_arn
  environment       = terraform.workspace
}

module "apigateway" {
  source           = "./apigateway"
  environment      = terraform.workspace
  api_handler_arn  = module.apihandler.api_handler_invoke_arn
  api_handler_name = module.apihandler.api_handler_name
}

locals {
  environment         = terraform.workspace
  archive_bucket_name = "order-archive-${local.environment}-${data.aws_caller_identity.current.account_id}"
  orders_table_name   = "orders-table-${local.environment}"
}