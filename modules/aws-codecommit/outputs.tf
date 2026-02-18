output "repository_name" {
  description = "Name of the CodeCommit repository"
  value       = aws_codecommit_repository.this.repository_name
}

output "clone_url_http" {
  description = "HTTP clone URL for the repository"
  value       = aws_codecommit_repository.this.clone_url_http
}

output "clone_url_ssh" {
  description = "SSH clone URL for the repository"
  value       = aws_codecommit_repository.this.clone_url_ssh
}

output "arn" {
  description = "ARN of the CodeCommit repository"
  value       = aws_codecommit_repository.this.arn
}
