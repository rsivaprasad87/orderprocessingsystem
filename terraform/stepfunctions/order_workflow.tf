resource "aws_sfn_state_machine" "order_workflow" {
  name     = "${var.project_name}-${terraform.workspace}-order-workflow"
  role_arn = var.step_function_role_arn

  definition = jsonencode({
    StartAt = "ValidateOrder",
    States = {
      ValidateOrder = {
        Type     = "Task",
        Resource = var.lambda_arns["validate_order"],
        Catch = [{
          ErrorEquals = ["States.ALL"],
          Next        = "Failed"
        }],
        Next = "CheckDuplicate"
      },

      CheckDuplicate = {
        Type = "Choice",
        Choices = [
          {
            Variable  = "$.duplicate",
            IsPresent = true,
            Next      = "DuplicateOrder"
          }
        ],
        Default = "ProcessPayment"
      },

      DuplicateOrder = {
        Type  = "Fail",
        Error = "DuplicateOrder",
        Cause = "Order already processed"
      },

      ProcessPayment = {
        Type     = "Task",
        Resource = var.lambda_arns["process_payment"],
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 2,
          MaxAttempts     = 3,
          BackoffRate     = 2.0
        }],
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "ReleaseInventory"
        }],
        Next = "ReserveInventory"
      },

      ReserveInventory = {
        Type     = "Task",
        Resource = var.lambda_arns["reserve_inventory"],
        Catch = [{
          ErrorEquals = ["States.ALL"],
          ResultPath  = "$.error",
          Next        = "ReleaseInventory"
        }],
        Next = "ArchiveOrder"
      },

      ArchiveOrder = {
        Type     = "Task",
        Resource = var.lambda_arns["archive_order"],
        Retry = [{
          ErrorEquals     = ["States.ALL"],
          IntervalSeconds = 3,
          MaxAttempts     = 2,
          BackoffRate     = 2.0
        }],
        Catch = [{
          ErrorEquals = ["States.ALL"],
          Next        = "ReleaseInventory"
        }],
        Next = "FinalizeOrder"
      },

      ReleaseInventory = {
        Type     = "Task",
        Resource = var.lambda_arns["release_inventory"],
        Next     = "Failed"
      },

      FinalizeOrder = {
        Type     = "Task",
        Resource = var.lambda_arns["finalize_order"],
        End      = true
      },

      Failed = {
        Type  = "Fail",
        Error = "OrderFailed",
        Cause = "Order processing failed"
      }
    }
  })
}