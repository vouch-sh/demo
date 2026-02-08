terraform {
  required_version = ">= 1.5"
}

provider "aws" {
  region = "us-east-1"
}

provider "google" {
  project = var.gcp_project_id
}

provider "kubernetes" {
  # Configure via KUBECONFIG env var or explicit config_path
}

module "vouch_demo" {
  source = "../../"

  vouch_issuer_url = var.vouch_issuer_url
  gcp_project_id   = var.gcp_project_id

  # Toggle providers as needed:
  # aws_enabled = false
  # gcp_enabled = false
  # k8s_enabled = false
}

variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch"
  type        = string
}

variable "gcp_project_id" {
  description = "GCP project ID"
  type        = string
}

output "aws_oidc_provider_arn" {
  value = module.vouch_demo.aws_oidc_provider_arn
}

output "aws_role_arn" {
  value = module.vouch_demo.aws_role_arn
}

output "gcp_workload_identity_pool_name" {
  value = module.vouch_demo.gcp_workload_identity_pool_name
}

output "gcp_service_account_email" {
  value = module.vouch_demo.gcp_service_account_email
}

output "k8s_namespace" {
  value = module.vouch_demo.k8s_namespace
}

output "k8s_service_account_name" {
  value = module.vouch_demo.k8s_service_account_name
}
