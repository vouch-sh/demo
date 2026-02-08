variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch (e.g. https://auth.vouch.sh)"
  type        = string

  validation {
    condition     = startswith(var.vouch_issuer_url, "https://")
    error_message = "The issuer URL must use HTTPS."
  }
}

variable "vouch_audiences" {
  description = "Allowed audience values in Vouch-issued OIDC tokens"
  type        = list(string)
  default     = ["sts.amazonaws.com"]
}

variable "role_name" {
  description = "Name of the IAM role for Vouch-authenticated workloads"
  type        = string
  default     = "vouch-demo"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
