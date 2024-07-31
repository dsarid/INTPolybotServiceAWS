variable "public_subnets" {
  type = list(string)
}

variable "y5-env" {
  type = string
  description = "var.env"
}

variable "y5-owner" {
  type = string
  description = "var.owner"
}

variable "y5-region" {
  type = string
  description = "var.region"
}

variable "y5-keyName" {
  type = string
}

variable "vpc_id" {
  type = string
  description = "module.app_vpc.vpc_id"
}

variable "dynamodb_table_arn" {
  type = string
  description = "module.dynamodb_table.dynamodb_table_arn"
}

variable "s3_arn" {
  type = string
  description = "aws_s3_bucket.main-bucket.arn"
}

variable "sqs_arn" {
  type = string
  description = "aws_sqs_queue.polybot-sqs.arn"
}
