# Order Processing System -- AWS Serverless Project

## Overview

This project is a production-style serverless Order Processing System
built using Terraform and AWS services. It provisions infrastructure for
secure order intake, workflow orchestration, and persistence using
Infrastructure as Code (IaC).

------------------------------------------------------------------------

# Architecture Diagram

``` text
                           +----------------------+
                           |   Client / Postman   |
                           | Spring Boot / cURL   |
                           +----------+-----------+
                                      |
                                      v
                           +----------------------+
                           |      API Gateway      |
                           |   POST /orders API    |
                           +----------+-----------+
                                      |
                                      v
                           +----------------------+
                           |   Lambda Function     |
                           | Order Intake Handler  |
                           +----------+-----------+
                                      |
                                      v
                           +----------------------+
                           |   AWS Step Functions  |
                           | Order Workflow Engine |
                           +-----+-----------+----+
                                 |           |
                     +-----------+           +------------+
                     v                                    v
          +----------------------+            +----------------------+
          |   DynamoDB Table      |            | CloudWatch Logs      |
          | Order Persistence     |            | Monitoring/Debugging |
          +----------------------+            +----------------------+

Infrastructure Provisioning:
+---------------------------------------------------------------+
| Terraform (Local / GitHub Actions CI/CD)                     |
|   - S3 Remote Backend (terraform.tfstate)                    |
|   - DynamoDB State Lock                                      |
|   - IAM Roles & Policies                                     |
|   - API Gateway / Lambda / Step Functions / DynamoDB         |
+---------------------------------------------------------------+
```

------------------------------------------------------------------------

# Key AWS Services

-   API Gateway
-   AWS Lambda
-   AWS Step Functions
-   DynamoDB
-   IAM
-   CloudWatch
-   S3 (Terraform Remote Backend)
-   DynamoDB (Terraform Locking)

------------------------------------------------------------------------

# Prerequisites

-   AWS Account
-   AWS CLI configured
-   Terraform \>= 1.x
-   GitHub account
-   Postman or cURL

------------------------------------------------------------------------

# Local Setup Guide

## Step 1: Clone Repository

``` bash
git clone https://github.com/rsivaprasad87/orderprocessingsystem.git
cd orderprocessingsystem
```

## Step 2: Configure AWS Credentials

``` bash
aws configure
```

## Step 3: Deploy Terraform Backend First
- The terrform-backend directory should be outside of the main project folder orderprocessingsystem
- Only to upload it to github as a single project it  is added within the main project folder 

``` bash
cd terraform-backend
terraform init
terraform apply
```

## Step 4: Development workspace setup 

- This project uses Terraform Workspaces to isolate environments like dev, QA and Prod

``` bash
terraform workspace new dev
terraform workspace select dev
terraform workspace list
terraform workspace show
```

## Step 5: Deploy Main Infrastructure

``` bash
cd terraform
terraform init 
terraform validate
terraform plan 
terraform apply 
```

## Step 5: Deploy Terraform Backend Integration

``` bash
cd terraform-backend-integration
terraform init 
terraform validate
terraform plan 
terraform apply 
```

------------------------------------------------------------------------

# Testing API Gateway

## Get Invoke URL

``` bash
terraform output api_invoke_url
```

## Test with cURL or postman

``` bash
curl -X POST https://your-api-id.execute-api.us-east-1.amazonaws.com/orders -H "Content-Type: application/json" -d '{
  "orderId": "ORD01",
  "customerId": "CUST",
  "items": [
    {
      "productId": "P1",
      "qty": 2
    }
  ],
  "totalAmount": 90.5,
  "simulatePaymentFailure": false
}'
```

------------------------------------------------------------------------

# GitHub Actions 

Push to `main` branch:

``` bash
git add .
git commit -m "Deploy infrastructure"
git push origin main
```
------------------------------------------------------------------------

# Common Errors & Fixes

## 1. Provider Registry Error

### Error:

``` bash
could not retrieve provider hashicorp/aws
```

### Fix:

``` bash
terraform init -upgrade
```

------------------------------------------------------------------------

## 2. State Lock Error

### Error:

``` bash
Error acquiring the state lock
```

### Fix:

Check DynamoDB lock table or:

``` bash
terraform force-unlock LOCK_ID
```

------------------------------------------------------------------------

## 3. Lambda ZIP Path Error

### Fix:

Ensure correct archive path:

``` hcl
Zip command in windows  : Compress-Archive -Path * -DestinationPath ../../apilambda/start_order.zip -Force
```

------------------------------------------------------------------------

## 4. API Gateway No Stage

### Fix:

Deploy API or use default stage.

------------------------------------------------------------------------

## 5. Circular Dependency

### Fix:

Separate IAM/Lambda/API dependencies into modules.

------------------------------------------------------------------------


# Cleanup

``` bash
terraform destroy -var-file=environments/dev/terraform.tfvars
```

------------------------------------------------------------------------

# Note

This README is designed as a beginner-to-advanced deployment reference
for setting up the project from scratch locally and extending it into
production.
