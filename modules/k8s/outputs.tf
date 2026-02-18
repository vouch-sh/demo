output "namespace" {
  description = "Kubernetes namespace where Vouch resources are deployed"
  value       = kubernetes_namespace_v1.vouch.metadata[0].name
}

output "service_account_name" {
  description = "Name of the Kubernetes service account for Vouch"
  value       = kubernetes_service_account_v1.vouch.metadata[0].name
}

output "config_map_name" {
  description = "Name of the ConfigMap containing Vouch configuration"
  value       = kubernetes_config_map_v1.vouch.metadata[0].name
}
