terraform {
  backend "s3" {
    bucket         = "order-process-state-dev-616640453658"
    key            = "orderprocessing/dev/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "order-process-state-dev"
    encrypt        = true
  }
}
