variable "remote_envfile_path" {
  type = string
  description = "path of the env file at the remote machine"
  default = "home/ubuntu/.env"
}

variable "s3_name" {
  type = string
  description = "aws_s3_bucket.main-bucket.bucket"
}
variable "dynamo_table_name" {
  type = string
  description = "module.dynamodb_table.dynamodb_table_id"
}
variable "sqs_name" {
  type = string
  description = "aws_sqs_queue.polybot-sqs.name"
}
variable "dns_name" {
  type = string
  description = "aws_lb.main-lb.dns_name"
}


resource "local_file" "generate-env-vars" {
  filename = "tf-env-vars.env"
  content = <<EOT
echo "REGION=${var.y5-region}" > ${var.remote_envfile_path}
echo "S3_BUCKET=${var.s3_name}" >> ${var.remote_envfile_path}
echo "TELEGRAM_APP_URL=${var.dns_name}:80" >> ${var.remote_envfile_path}
echo "DYNAMO_NAME=${var.dynamo_table_name}" >> ${var.remote_envfile_path}
echo "SQS_QUEUE_NAME=${var.sqs_name}" >> ${var.remote_envfile_path}
EOT
}


resource "local_file" "compose_user_data_poly" {
  depends_on = [local_file.generate-env-vars]
  filename = "polybot-user-data"
  content = <<EOT
${file("./polybot/scripts/aws-conf.txt")}
#!/bin/bash
${local_file.generate-env-vars.content}
${file("yolo5/scripts/yolo5-user-data-part")}
${file("yolo5/scripts/close-aws-conf")}"
EOT
}
