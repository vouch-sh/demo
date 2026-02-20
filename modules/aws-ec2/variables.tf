variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "vouch-demo"
}

variable "subnet_id" {
  description = "Subnet ID to launch the instance in"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for the security group"
  type        = string
}

variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch (used to fetch SSH CA public key)"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
