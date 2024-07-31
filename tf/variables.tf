variable "env" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "keyName" {
  type = string
}

variable "botToken" {
  description = "telegram bot token"
  type = string
}

variable "owner" {
  description = "my name"
  type = string
  default = "danielms"
}

variable "region" {
  description = "default region"
  type = string
#   default = "eu-central-1"
}
