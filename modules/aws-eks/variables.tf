variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "vouch-demo"
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (minimum 2 AZs required)"
  type        = list(string)
}

variable "vouch_role_arn" {
  description = "ARN of the Vouch IAM role to grant EKS cluster admin access"
  type        = string
  default     = ""
}

variable "create_access_entry" {
  description = "Whether to create an EKS access entry for the Vouch IAM role"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
