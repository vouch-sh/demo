# AWS outputs
output "aws_oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider for Vouch"
  value       = var.aws_enabled ? module.aws[0].oidc_provider_arn : null
}

output "aws_role_arn" {
  description = "ARN of the IAM role that Vouch-authenticated workloads can assume"
  value       = var.aws_enabled ? module.aws[0].role_arn : null
}

# GCP outputs
output "gcp_workload_identity_pool_name" {
  description = "Full resource name of the GCP Workload Identity Pool"
  value       = var.gcp_enabled ? module.gcp[0].workload_identity_pool_name : null
}

output "gcp_workload_identity_provider_name" {
  description = "Full resource name of the GCP Workload Identity Pool OIDC Provider"
  value       = var.gcp_enabled ? module.gcp[0].workload_identity_provider_name : null
}

output "gcp_service_account_email" {
  description = "Email of the GCP service account for Vouch workloads"
  value       = var.gcp_enabled ? module.gcp[0].service_account_email : null
}

# Kubernetes outputs
output "k8s_namespace" {
  description = "Kubernetes namespace where Vouch resources are deployed"
  value       = var.k8s_enabled ? module.k8s[0].namespace : null
}

output "k8s_service_account_name" {
  description = "Name of the Kubernetes service account for Vouch"
  value       = var.k8s_enabled ? module.k8s[0].service_account_name : null
}
