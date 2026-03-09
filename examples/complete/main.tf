terraform {
  required_version = ">= 1.10"
}

provider "aws" {
  region = "us-east-1"
}

module "vouch_demo" {
  source = "../../"

  vouch_issuer_url = var.vouch_issuer_url

  # Toggle providers as needed:
  # aws_enabled = false
  # k8s_enabled = false

  # Demo service modules (all default to false):
  codecommit_enabled          = var.codecommit_enabled
  codeartifact_enabled        = var.codeartifact_enabled
  ecr_enabled                 = var.ecr_enabled
  ec2_enabled                 = var.ec2_enabled
  eks_enabled                 = var.eks_enabled
  rds_enabled                 = var.rds_enabled
  redshift_serverless_enabled = var.redshift_serverless_enabled
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

variable "rds_enabled" {
  description = "Whether to create an RDS PostgreSQL instance with IAM auth"
  type        = bool
  default     = false
}

variable "redshift_serverless_enabled" {
  description = "Whether to create a Redshift Serverless workgroup with IAM auth"
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

output "codeartifact_npm_store_repository_name" {
  value = module.vouch_demo.codeartifact_npm_store_repository_name
}

output "codeartifact_pypi_store_repository_name" {
  value = module.vouch_demo.codeartifact_pypi_store_repository_name
}

# ECR outputs
output "ecr_repository_url" {
  value = module.vouch_demo.ecr_repository_url
}

# EC2 outputs
output "ec2_instance_id" {
  value = module.vouch_demo.ec2_instance_id
}

output "ec2_instance_public_ip" {
  value = module.vouch_demo.ec2_instance_public_ip
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

output "vouch_setup_codeartifact_pip" {
  value = module.vouch_demo.vouch_setup_codeartifact_pip
}

output "vouch_setup_docker" {
  value = module.vouch_demo.vouch_setup_docker
}

output "vouch_setup_eks" {
  value = module.vouch_demo.vouch_setup_eks
}

# RDS outputs
output "rds_address" {
  value = module.vouch_demo.rds_address
}

output "rds_port" {
  value = module.vouch_demo.rds_port
}

output "rds_database_name" {
  value = module.vouch_demo.rds_database_name
}

output "rds_connect_command" {
  value = module.vouch_demo.rds_connect_command
}

# Redshift Serverless outputs
output "redshift_serverless_workgroup_name" {
  value = module.vouch_demo.redshift_serverless_workgroup_name
}

output "redshift_serverless_endpoint_address" {
  value = module.vouch_demo.redshift_serverless_endpoint_address
}

output "redshift_serverless_database_name" {
  value = module.vouch_demo.redshift_serverless_database_name
}

output "redshift_connect_command" {
  value = module.vouch_demo.redshift_connect_command
}

# Demo commands
output "codecommit_clone_command" {
  value = module.vouch_demo.codecommit_clone_command
}

output "ssm_connect_command" {
  value = module.vouch_demo.ssm_connect_command
}

output "ssh_connect_command" {
  value = module.vouch_demo.ssh_connect_command
}
