# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

### Common Terraform Workflow

```powershell
# Initialize (run from terraform/ root)
terraform init

# Select or create a workspace (dev or prod)
terraform workspace select dev
terraform workspace new dev

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy
```

### Backend Configuration

The backend config lives in `terraform-backend-integration/backend.tf` and is **maintained separately** from the root module — the root `provider.tf` has **no `backend {}` block**. You must always pass the backend config explicitly on init:

```powershell
terraform init -backend-config="terraform-backend-integration/backend.tf"
```

If you see `Error: Backend configuration changed` (e.g., after a Terraform version upgrade), use `-reconfigure` to re-register the same backend without migrating state:

```powershell
terraform init -reconfigure -backend-config="terraform-backend-integration/backend.tf"
```

Only use `-migrate-state` if the S3 bucket, key, or region actually changed.

Backend: S3 bucket `order-process-state-dev-616640453658` (ap-south-1), DynamoDB lock table `order-process-state-dev`.

### Packaging Lambda Functions

Lambda zip files must be built manually before `terraform apply`. Source code lives in `lambda_src/<function_name>/`, and the compiled zips are expected at:
- `lambda/<function_name>.zip` — for the 6 workflow Lambdas
- `apilambda/start_order.zip` — for the API handler Lambda

There is no automated build script; zip each handler directory manually.

## Architecture

This is a **serverless order processing system** on AWS, fully defined in Terraform with 7 child modules.

### Request Flow

```
POST /orders
  → API Gateway (HTTP API, ap-south-1)
  → api_handler Lambda (start_order.py)
  → Step Functions state machine
  → ValidateOrder → CheckDuplicate → ProcessPayment → ReserveInventory → ArchiveOrder → FinalizeOrder
                                                   ↘ (any failure) → ReleaseInventory → Failed
```

### Module Dependency Chain

```
dynamodb ──┐
s3 ────────┼──→ iam ──→ lambda ──→ stepfunctions ──→ apilambda ──→ apigateway
```

All environment naming uses `terraform.workspace` (e.g., `dev`, `prod`).

### Resource Naming Convention

`{project_name_prefix}-{workspace}-{resource}` — default prefix is `order-processing`.

Key computed names (defined as `locals` in `main.tf`):
- DynamoDB table: `orders-table-{workspace}`
- S3 archive bucket: `order-archive-{workspace}-{account_id}` (account ID from `aws_caller_identity`)

### Step Functions State Machine

The workflow is defined inline in `stepfunctions/order_workflow.tf` as a `jsonencode` block. It implements a saga pattern:
- **Happy path:** ValidateOrder → CheckDuplicate (Choice) → ProcessPayment → ReserveInventory → ArchiveOrder → FinalizeOrder
- **Compensation:** Any failure after payment routes to ReleaseInventory → Failed
- **Retries:** ProcessPayment retries 3× (backoff 2×), ArchiveOrder retries 2×
- **Duplicate detection:** CheckDuplicate inspects `$.duplicate` field presence in the state output

### Lambda Functions

| Function | Handler | Timeout |
|---|---|---|
| validate_order | `handler.handler` | 10s |
| process_payment | `handler.lambda_handler` | 15s |
| reserve_inventory | `handler.lambda_handler` | 10s |
| archive_order | `handler.lambda_handler` | 5s |
| finalize_order | `handler.lambda_handler` | 15s |
| release_inventory | `handler.lambda_handler` | 10s |
| api_handler (start_order) | `start_order.lambda_handler` | default |

The 6 workflow Lambdas share a single IAM role (`lambda-execution-role`) created in the `iam` module. The API handler (`apilambda` module) has its own inline role with `states:StartExecution` permission.

### Known Typos in Filenames

- `iam/lamba_role.tf` — missing 'b' in "lambda"
- `stepfunctions/ouputs.tf` — missing 't' in "outputs"

Do not rename these files without verifying no external references (e.g., CI scripts) depend on them.
