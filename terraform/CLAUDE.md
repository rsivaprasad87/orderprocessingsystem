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

The CI/CD pipeline rebuilds all zips automatically. For local runs, build them manually:

```bash
# Workflow lambdas
for func in validate_order process_payment reserve_inventory archive_order finalize_order release_inventory; do
  (cd "lambda_src/${func}" && zip -r "../../lambda/${func}.zip" .)
done
# API handler
(cd lambda_src/start_order && zip -r ../../apilambda/start_order.zip .)
```

Zip files must be present before `terraform plan/apply`. Source is in `lambda_src/<function>/`, output goes to `lambda/<function>.zip` and `apilambda/start_order.zip`.

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

## CI/CD Pipeline

### Overview

GitHub Actions runs two workflows (`.github/workflows/`):
- **`terraform-plan.yml`** — triggered on pull requests targeting `main`; posts the plan output as a PR comment
- **`terraform-apply.yml`** — triggered on push/merge to `main`; runs `terraform apply -auto-approve` against the `dev` workspace

Authentication uses **OIDC** (no long-lived AWS keys stored in GitHub). Both workflows assume the IAM role stored in the `AWS_ROLE_ARN` GitHub Secret.

### One-time OIDC Setup (run before first pipeline use)

```bash
cd terraform/oidc
terraform init
terraform apply -var="github_repo=YOUR_GITHUB_USERNAME/YOUR_REPO_NAME"
# Copy the output role ARN into GitHub → Settings → Secrets → AWS_ROLE_ARN
```

This creates the OIDC provider and a scoped IAM role in AWS. State is stored locally in `terraform/oidc/terraform.tfstate` — do not delete it.

### Adding the GitHub Secret

1. Go to your GitHub repo → **Settings → Secrets and variables → Actions**
2. Click **New repository secret**
3. Name: `AWS_ROLE_ARN`, Value: the ARN output from the OIDC setup above

### Known Typos in Filenames

- `iam/lamba_role.tf` — missing 'b' in "lambda"
- `stepfunctions/ouputs.tf` — missing 't' in "outputs"

Do not rename these files without verifying no external references (e.g., CI scripts) depend on them.
