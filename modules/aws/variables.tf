variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch (e.g. https://auth.vouch.sh)"
  type        = string

  validation {
    condition     = startswith(var.vouch_issuer_url, "https://")
    error_message = "The issuer URL must use HTTPS."
  }
}

variable "role_name" {
  description = "Name of the IAM role for Vouch-authenticated workloads"
  type        = string
  default     = "vouch-demo"
}

variable "demo_services_enabled" {
  description = "Whether to attach demo service permissions (CodeCommit, CodeArtifact, ECR, SSM, EKS, Bedrock)"
  type        = bool
  default     = false
}

variable "codecommit_repository_arn" {
  description = "ARN of the CodeCommit repository to scope permissions (empty string allows all)"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
