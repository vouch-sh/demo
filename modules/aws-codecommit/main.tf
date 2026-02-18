resource "aws_codecommit_repository" "this" {
  repository_name = var.name_prefix
  description     = "Vouch demo repository for git credential helper testing"

  tags = var.tags
}
