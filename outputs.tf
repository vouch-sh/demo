# AWS outputs
output "aws_oidc_provider_arn" {
  description = "ARN of the AWS IAM OIDC provider for Vouch"
  value       = var.aws_enabled ? module.aws[0].oidc_provider_arn : null
}

output "aws_role_arn" {
  description = "ARN of the IAM role that Vouch-authenticated workloads can assume"
  value       = var.aws_enabled ? module.aws[0].role_arn : null
}

# CodeCommit outputs
output "codecommit_clone_url_http" {
  description = "HTTP clone URL for the CodeCommit repository"
  value       = var.codecommit_enabled ? module.aws_codecommit[0].clone_url_http : null
}

output "codecommit_clone_url_ssh" {
  description = "SSH clone URL for the CodeCommit repository"
  value       = var.codecommit_enabled ? module.aws_codecommit[0].clone_url_ssh : null
}

# CodeArtifact outputs
output "codeartifact_domain_name" {
  description = "Name of the CodeArtifact domain"
  value       = var.codeartifact_enabled ? module.aws_codeartifact[0].domain_name : null
}

output "codeartifact_repository_name" {
  description = "Name of the CodeArtifact repository"
  value       = var.codeartifact_enabled ? module.aws_codeartifact[0].repository_name : null
}

output "codeartifact_domain_owner" {
  description = "AWS account ID that owns the CodeArtifact domain"
  value       = var.codeartifact_enabled ? module.aws_codeartifact[0].domain_owner : null
}

# ECR outputs
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = var.ecr_enabled ? module.aws_ecr[0].repository_url : null
}

# EC2 outputs
output "ec2_instance_id" {
  description = "ID of the EC2 instance (use with SSM start-session)"
  value       = var.ec2_enabled ? module.aws_ec2[0].instance_id : null
}

output "ec2_instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = var.ec2_enabled ? module.aws_ec2[0].instance_public_ip : null
}

# EKS outputs
output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = var.eks_enabled ? module.aws_eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint URL of the EKS cluster"
  value       = var.eks_enabled ? module.aws_eks[0].cluster_endpoint : null
}

output "eks_cluster_certificate_authority" {
  description = "Base64-encoded certificate authority data for the EKS cluster"
  value       = var.eks_enabled ? module.aws_eks[0].cluster_certificate_authority : null
}

# Setup commands — run once after deploy
output "vouch_setup_aws" {
  description = "Run this command to configure Vouch for AWS"
  value       = var.aws_enabled ? "vouch setup aws --role ${module.aws[0].role_arn}" : null
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
    "--repository ${module.aws_codeartifact[0].repository_name}",
    "--domain ${module.aws_codeartifact[0].domain_name}",
    "--domain-owner ${module.aws_codeartifact[0].domain_owner}",
    "--region ${data.aws_region.current.region}",
  ]) : null
}

output "vouch_setup_docker" {
  description = "Run this command to configure Vouch for ECR"
  value       = var.ecr_enabled ? "vouch setup docker --configure ${split("/", module.aws_ecr[0].repository_url)[0]}" : null
}

output "vouch_setup_eks" {
  description = "Run this command to configure kubectl for EKS"
  value       = var.eks_enabled ? "aws eks update-kubeconfig --name ${module.aws_eks[0].cluster_name} --region ${data.aws_region.current.region} --profile vouch" : null
}

# Demo commands
output "codecommit_clone_command" {
  description = "Run this command to clone the CodeCommit repository"
  value       = var.codecommit_enabled ? "git clone codecommit://vouch@${module.aws_codecommit[0].repository_name}" : null
}

output "ssm_connect_command" {
  description = "Run this command to start an SSM session on the EC2 instance"
  value       = var.ec2_enabled ? "aws ssm start-session --target ${module.aws_ec2[0].instance_id} --region ${data.aws_region.current.region} --profile vouch" : null
}

output "ssh_connect_command" {
  description = "Run this command to SSH into the EC2 instance with Vouch certificates"
  value       = var.ec2_enabled ? "ssh -t -i ~/.ssh/id_ed25519_vouch ec2-user@${module.aws_ec2[0].instance_public_ip}" : null
}
