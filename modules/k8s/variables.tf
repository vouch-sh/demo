variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch"
  type        = string
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
