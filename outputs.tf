# AWS outputs
output "aws_oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider for Vouch"
  value       = one(module.aws[*].oidc_provider_arn)
}

output "aws_role_arn" {
  description = "ARN of the IAM role that Vouch-authenticated workloads can assume"
  value       = one(module.aws[*].role_arn)
}

# CodeCommit outputs
output "codecommit_clone_url_http" {
  description = "HTTP clone URL for the CodeCommit repository"
  value       = one(module.aws_codecommit[*].clone_url_http)
}

output "codecommit_clone_url_ssh" {
  description = "SSH clone URL for the CodeCommit repository"
  value       = one(module.aws_codecommit[*].clone_url_ssh)
}

# CodeArtifact outputs
output "codeartifact_domain_name" {
  description = "Name of the CodeArtifact domain"
  value       = one(module.aws_codeartifact[*].domain_name)
}

output "codeartifact_repository_name" {
  description = "Name of the CodeArtifact repository"
  value       = one(module.aws_codeartifact[*].repository_name)
}

output "codeartifact_domain_owner" {
  description = "AWS account ID that owns the CodeArtifact domain"
  value       = one(module.aws_codeartifact[*].domain_owner)
}

output "codeartifact_npm_store_repository_name" {
  description = "Name of the CodeArtifact npm-store upstream repository"
  value       = one(module.aws_codeartifact[*].npm_store_repository_name)
}

output "codeartifact_pypi_store_repository_name" {
  description = "Name of the CodeArtifact pypi-store upstream repository"
  value       = one(module.aws_codeartifact[*].pypi_store_repository_name)
}

# ECR outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = one(module.aws_ecr[*].repository_url)
}

# EC2 outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance (use with SSM start-session)"
  value       = one(module.aws_ec2[*].instance_id)
}

output "ec2_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = one(module.aws_ec2[*].instance_public_ip)
}

# EKS outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = one(module.aws_eks[*].cluster_name)
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = one(module.aws_eks[*].cluster_endpoint)
}

output "eks_cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the EKS cluster"
  value       = one(module.aws_eks[*].cluster_certificate_authority)
}

# Setup commands — run once after deploy
output "vouch_setup_aws" {
  description = "Run this command to configure Vouch for AWS"
  value       = var.aws_enabled ? "vouch setup aws --role ${one(module.aws[*].role_arn)} --region ${data.aws_region.current.region}" : null
}

output "vouch_setup_codecommit" {
  description = "Run this command to configure Vouch for CodeCommit"
  value       = var.codecommit_enabled ? "vouch setup codecommit --profile vouch --configure" : null
}

output "vouch_setup_codeartifact_npm" {
  description = "Run this command to configure Vouch for CodeArtifact (npm)"
  value = var.codeartifact_enabled ? join(" ", [
    "vouch setup codeartifact",
    "--tool npm",
    "--repository ${one(module.aws_codeartifact[*].repository_name)}",
    "--domain ${one(module.aws_codeartifact[*].domain_name)}",
    "--domain-owner ${one(module.aws_codeartifact[*].domain_owner)}",
    "--region ${data.aws_region.current.region}",
  ]) : null
}

output "vouch_setup_codeartifact_pip" {
  description = "Run this command to configure Vouch for CodeArtifact (pip)"
  value = var.codeartifact_enabled ? join(" ", [
    "vouch setup codeartifact",
    "--tool pip",
    "--repository ${one(module.aws_codeartifact[*].repository_name)}",
    "--domain ${one(module.aws_codeartifact[*].domain_name)}",
    "--domain-owner ${one(module.aws_codeartifact[*].domain_owner)}",
    "--region ${data.aws_region.current.region}",
  ]) : null
}

output "vouch_setup_docker" {
  description = "Run this command to configure Vouch for ECR"
  value       = var.ecr_enabled ? "vouch setup docker --configure ${split("/", one(module.aws_ecr[*].repository_url))[0]}" : null
}

output "vouch_setup_eks" {
  description = "Run this command to configure kubectl for EKS"
  value       = var.eks_enabled ? "vouch setup eks --cluster ${one(module.aws_eks[*].cluster_name)} --profile vouch" : null
}

# Demo commands
output "codecommit_clone_command" {
  description = "Run this command to clone the CodeCommit repository"
  value       = var.codecommit_enabled ? "git clone codecommit://vouch@${one(module.aws_codecommit[*].repository_name)}" : null
}

output "ssm_connect_command" {
  description = "Run this command to start an SSM session on the EC2 instance"
  value       = var.ec2_enabled ? "aws ssm start-session --target ${one(module.aws_ec2[*].instance_id)} --profile vouch" : null
}

output "ssh_connect_command" {
  description = "Run this command to SSH into the EC2 instance with Vouch certificates"
  value       = var.ec2_enabled ? "ssh -t -i ~/.ssh/id_ed25519_vouch ec2-user@${one(module.aws_ec2[*].instance_public_ip)}" : null
}

# RDS outputs
output "rds_address" {
  description = "Hostname of the RDS instance"
  value       = one(module.aws_rds[*].address)
}

output "rds_port" {
  description = "Port of the RDS instance"
  value       = one(module.aws_rds[*].port)
}

output "rds_database_name" {
  description = "Name of the default database"
  value       = one(module.aws_rds[*].database_name)
}

output "rds_connect_command" {
  description = "Run this command to connect to the RDS instance with Vouch IAM auth"
  value = var.rds_enabled ? join("", [
    "vouch exec --type rds",
    " --rds-hostname ${one(module.aws_rds[*].address)}",
    " --rds-port ${one(module.aws_rds[*].port)}",
    " --rds-username vouch",
    " -- psql",
    " -d ${one(module.aws_rds[*].database_name)}",
  ]) : null
}

# Redshift Serverless outputs
output "redshift_serverless_workgroup_name" {
  description = "Name of the Redshift Serverless workgroup"
  value       = one(module.aws_redshift_serverless[*].workgroup_name)
}

output "redshift_serverless_endpoint_address" {
  description = "Hostname of the Redshift Serverless endpoint"
  value       = one(module.aws_redshift_serverless[*].endpoint_address)
}

output "redshift_serverless_endpoint_port" {
  description = "Port of the Redshift Serverless endpoint"
  value       = one(module.aws_redshift_serverless[*].endpoint_port)
}

output "redshift_serverless_database_name" {
  description = "Name of the default Redshift database"
  value       = one(module.aws_redshift_serverless[*].database_name)
}

output "redshift_connect_command" {
  description = "Run this command to connect to Redshift Serverless with Vouch IAM auth"
  value = var.redshift_serverless_enabled ? join("", [
    "vouch exec --type redshift",
    " --redshift-workgroup ${one(module.aws_redshift_serverless[*].workgroup_name)}",
    " -- psql",
    " -h ${one(module.aws_redshift_serverless[*].endpoint_address)}",
    " -p ${one(module.aws_redshift_serverless[*].endpoint_port)}",
    " -d ${one(module.aws_redshift_serverless[*].database_name)}",
  ]) : null
}
