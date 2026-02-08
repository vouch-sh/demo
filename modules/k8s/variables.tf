variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch"
  type        = string
}

variable "vouch_audiences" {
  description = "List of allowed audience values in Vouch-issued OIDC tokens"
  type        = list(string)
  default     = ["vouch"]
}

variable "namespace" {
  description = "Kubernetes namespace for Vouch resources"
  type        = string
  default     = "vouch"
}

variable "aws_role_arn" {
  description = "ARN of the AWS IAM role for IRSA annotation (leave empty to skip)"
  type        = string
  default     = ""
}

variable "gcp_service_account" {
  description = "Email of the GCP service account for GKE Workload Identity annotation (leave empty to skip)"
  type        = string
  default     = ""
}
