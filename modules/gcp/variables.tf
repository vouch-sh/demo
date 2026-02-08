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
  default     = ["vouch"]
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "pool_id" {
  description = "ID for the Workload Identity Pool"
  type        = string
  default     = "vouch-demo"
}

variable "provider_id" {
  description = "ID for the Workload Identity Pool OIDC Provider"
  type        = string
  default     = "vouch-oidc"
}

variable "service_account_id" {
  description = "ID for the GCP service account"
  type        = string
  default     = "vouch-demo"
}
