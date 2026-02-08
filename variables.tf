variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for the Vouch identity provider (e.g. https://auth.vouch.sh)"
  type        = string

  validation {
    condition     = startswith(var.vouch_issuer_url, "https://")
    error_message = "The issuer URL must use HTTPS."
  }
}

variable "aws_enabled" {
  description = "Whether to deploy AWS Vouch integration resources"
  type        = bool
  default     = true
}

variable "gcp_enabled" {
  description = "Whether to deploy GCP Vouch integration resources"
  type        = bool
  default     = true
}

variable "gcp_project_id" {
  description = "GCP project ID where Workload Identity resources will be created (required when gcp_enabled = true)"
  type        = string
  default     = ""
}

variable "k8s_enabled" {
  description = "Whether to deploy Kubernetes Vouch integration resources"
  type        = bool
  default     = true
}
