variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for the Vouch identity provider (e.g. https://us.vouch.sh)"
  type        = string

  validation {
    condition     = startswith(var.vouch_issuer_url, "https://")
    error_message = "The issuer URL must use HTTPS."
  }
}

variable "name_prefix" {
  description = "Prefix for resource names"
  type        = string
  default     = "vouch-demo"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_enabled" {
  description = "Whether to deploy AWS Vouch integration resources (IAM OIDC + role)"
  type        = bool
  default     = true
}

variable "k8s_enabled" {
  description = "Whether to deploy Kubernetes Vouch integration resources"
  type        = bool
  default     = true
}

variable "codecommit_enabled" {
  description = "Whether to create a CodeCommit repository for demo"
  type        = bool
  default     = false
}

variable "codeartifact_enabled" {
  description = "Whether to create CodeArtifact domain and repository for demo"
  type        = bool
  default     = false
}

variable "ecr_enabled" {
  description = "Whether to create an ECR repository for demo"
  type        = bool
  default     = false
}

variable "ec2_enabled" {
  description = "Whether to create an EC2 instance with SSM access for demo"
  type        = bool
  default     = false
}

variable "eks_enabled" {
  description = "Whether to create an EKS Auto Mode cluster for demo"
  type        = bool
  default     = false
}
