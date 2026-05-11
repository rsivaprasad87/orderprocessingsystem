variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "step_function_role_arn" {
  type = string
}

variable "lambda_arns" {
  type = map(string)
}


