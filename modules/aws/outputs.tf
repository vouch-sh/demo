output "oidc_provider_arn" {
  description = "ARN of the IAM OIDC provider for Vouch"
  value       = aws_iam_openid_connect_provider.vouch.arn
}

output "oidc_provider_url" {
  description = "URL of the IAM OIDC provider"
  value       = aws_iam_openid_connect_provider.vouch.url
}

output "role_arn" {
  description = "ARN of the IAM role for Vouch-authenticated workloads"
  value       = aws_iam_role.vouch.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.vouch.name
}
