output "workload_identity_pool_name" {
  description = "Full resource name of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.vouch.name
}

output "workload_identity_pool_id" {
  description = "ID of the Workload Identity Pool"
  value       = google_iam_workload_identity_pool.vouch.workload_identity_pool_id
}

output "workload_identity_provider_name" {
  description = "Full resource name of the Workload Identity Pool OIDC Provider"
  value       = google_iam_workload_identity_pool_provider.vouch.name
}

output "service_account_email" {
  description = "Email of the GCP service account for Vouch workloads"
  value       = google_service_account.vouch.email
}

output "service_account_name" {
  description = "Full resource name of the service account"
  value       = google_service_account.vouch.name
}
