resource "aws_dynamodb_table" "orders" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "orderId"
  range_key = "recordType"

  attribute {
    name = "orderId"
    type = "S"
  }

  attribute {
    name = "recordType"
    type = "S"
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = {
    Service = "order-processing"
    Env     = terraform.workspace
  }
}