variable "github_repo" {
  description = "GitHub repository in 'owner/repo' format (e.g. 'myuser/orderprocessingsystem')"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}
