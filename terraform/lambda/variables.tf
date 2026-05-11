variable "project_name" {
  type = string
}
variable "lambda_role_arn" {
  type = string
}

variable "environment" {
  type = string
}

variable "lambdas" {
  description = "Map of lambda configurations"
  type = map(object({
    handler  = string
    runtime  = string
    filename = string
    timeout  = number
  }))
}

variable "orders_table_name" {
  type = string
}

variable "archive_bucket_name" {
  type = string
}


