output "domain_name" {
  description = "Name of the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.domain
}

output "domain_arn" {
  description = "ARN of the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.arn
}

output "repository_name" {
  description = "Name of the CodeArtifact repository"
  value       = aws_codeartifact_repository.this.repository
}

output "repository_arn" {
  description = "ARN of the CodeArtifact repository"
  value       = aws_codeartifact_repository.this.arn
}

output "domain_owner" {
  description = "AWS account ID that owns the CodeArtifact domain"
  value       = aws_codeartifact_domain.this.owner
}
