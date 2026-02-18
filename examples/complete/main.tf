terraform {
  required_version = ">= 1.10"
}

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  # Configure via KUBECONFIG env var or explicit config_path
}

module "vouch_demo" {
  source = "../../"

  vouch_issuer_url = var.vouch_issuer_url

  # Toggle providers as needed:
  # aws_enabled = false
  # k8s_enabled = false

  # Demo service modules (all default to false):
  codecommit_enabled   = var.codecommit_enabled
  codeartifact_enabled = var.codeartifact_enabled
  ecr_enabled          = var.ecr_enabled
  ec2_enabled          = var.ec2_enabled
  eks_enabled          = var.eks_enabled
}

variable "vouch_issuer_url" {
  description = "The OIDC issuer URL for Vouch"
  type        = string
}

variable "codecommit_enabled" {
  description = "Whether to create a CodeCommit repository"
  type        = bool
  default     = false
}

variable "codeartifact_enabled" {
  description = "Whether to create CodeArtifact domain and repository"
  type        = bool
  default     = false
}

variable "ecr_enabled" {
  description = "Whether to create an ECR repository"
  type        = bool
  default     = false
}

variable "ec2_enabled" {
  description = "Whether to create an EC2 instance with SSM access"
  type        = bool
  default     = false
}

variable "eks_enabled" {
  description = "Whether to create an EKS Auto Mode cluster"
  type        = bool
  default     = false
}

# AWS identity outputs
output "aws_oidc_provider_arn" {
  value = module.vouch_demo.aws_oidc_provider_arn
}

output "aws_role_arn" {
  value = module.vouch_demo.aws_role_arn
}

# Kubernetes outputs
output "k8s_namespace" {
  value = module.vouch_demo.k8s_namespace
}

output "k8s_service_account_name" {
  value = module.vouch_demo.k8s_service_account_name
}

# CodeCommit outputs
output "codecommit_clone_url_http" {
  value = module.vouch_demo.codecommit_clone_url_http
}

# CodeArtifact outputs
output "codeartifact_domain_name" {
  value = module.vouch_demo.codeartifact_domain_name
}

output "codeartifact_repository_name" {
  value = module.vouch_demo.codeartifact_repository_name
}

# CodeArtifact outputs
output "codeartifact_domain_owner" {
  value = module.vouch_demo.codeartifact_domain_owner
}

# ECR outputs
output "ecr_repository_url" {
  value = module.vouch_demo.ecr_repository_url
}

# EC2 outputs
output "ec2_instance_id" {
  value = module.vouch_demo.ec2_instance_id
}

# EKS outputs
output "eks_cluster_name" {
  value = module.vouch_demo.eks_cluster_name
}

output "eks_cluster_endpoint" {
  value = module.vouch_demo.eks_cluster_endpoint
}

# Setup commands
output "vouch_setup_aws" {
  value = module.vouch_demo.vouch_setup_aws
}

output "vouch_setup_codecommit" {
  value = module.vouch_demo.vouch_setup_codecommit
}

output "vouch_setup_codeartifact_npm" {
  value = module.vouch_demo.vouch_setup_codeartifact_npm
}

output "vouch_setup_docker" {
  value = module.vouch_demo.vouch_setup_docker
}

output "vouch_setup_eks" {
  value = module.vouch_demo.vouch_setup_eks
}

# Demo commands
output "codecommit_clone_command" {
  value = module.vouch_demo.codecommit_clone_command
}

output "ssm_connect_command" {
  value = module.vouch_demo.ssm_connect_command
}
