output "ecr_name" {
  value = aws_ecr_repository.polybot-ecr.name
}

output "ecr_arn" {
  value = aws_ecr_repository.polybot-ecr.arn
}

output "ecr_url" {
  value = aws_ecr_repository.polybot-ecr.repository_url
}

output "ecr_registry" {
  value = aws_ecr_repository.polybot-ecr.registry_id
}
