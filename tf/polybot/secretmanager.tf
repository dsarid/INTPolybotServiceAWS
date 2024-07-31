
resource "aws_secretsmanager_secret" "telegram_token" {
  name = "tf-telegram-token-${uuid()}"
  lifecycle {
    ignore_changes = [name]
  }
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id     = aws_secretsmanager_secret.telegram_token.id
  secret_string = jsonencode({
    TELEGRAM_BOT_TOKEN = var.pb-token
  })
}
