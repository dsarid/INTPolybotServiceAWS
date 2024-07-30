variable "remote_envfile_path" {
  type = string
  description = "path of the env file at the remote machine"
  default = "home/ubuntu/.env"
}


resource "local_file" "generate-env-vars" {
  filename = "tf-env-vars.env"
  content = <<EOT
echo "S3_BUCKET=${aws_s3_bucket.main-bucket.bucket}" > ${var.remote_envfile_path}
echo "TELEGRAM_APP_URL=${aws_lb.main-lb.dns_name}:8443" >> ${var.remote_envfile_path}
echo "DYNAMO_NAME=${module.dynamodb_table.dynamodb_table_id}" >> ${var.remote_envfile_path}
echo "TELEGRAM_SECRET_TOKEN=${aws_secretsmanager_secret.telegram_token.name}" >> ${var.remote_envfile_path}
echo "SQS_QUEUE_NAME=${aws_sqs_queue.polybot-sqs.name}" >> ${var.remote_envfile_path}
echo "CERTIFICATE_ARN=${aws_acm_certificate.cert.arn}" >> ${var.remote_envfile_path}
EOT
}


resource "local_file" "compose_user_data_poly" {
  depends_on = [local_file.generate-env-vars]
  filename = "polybot-user-data"
  content = <<EOT
${file("./scripts/aws-conf.txt")}
#!/bin/bash
${local_file.generate-env-vars.content}
${file("scripts/poly-user-data-part")}
${file("scripts/close-aws-conf")}"
EOT
}
