variable "public_subnets" {
  type = list(string)
}

variable "pb-token" {
  type = string
  description = "var.botToken"
}

variable "pb-owner" {
  type = string
  description = "var.owner"
}

variable "pb-region" {
  type = string
  description = "var.region"
}

variable "lb_sg_id" {
  type = string
  description = "aws_security_group.lb-sg.id"
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

variable "cert_arn" {
  type = string
  description = "aws_acm_certificate.cert.arn"
}