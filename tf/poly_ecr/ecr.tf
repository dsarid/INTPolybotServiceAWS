resource "aws_ecr_repository" "polybot-ecr" {
  name = "polybot-ecr"
  image_scanning_configuration {
    scan_on_push = false
  }
  force_delete = true
  image_tag_mutability = "MUTABLE"
}
