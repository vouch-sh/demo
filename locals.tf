locals {
  vpc_needed            = var.ec2_enabled || var.eks_enabled
  demo_services_enabled = var.codecommit_enabled || var.codeartifact_enabled || var.ecr_enabled || var.ec2_enabled || var.eks_enabled

  ssh_authorized_principals = var.ec2_enabled ? [
    data.external.vouch_identity[0].result.email,
    split("@", data.external.vouch_identity[0].result.email)[0]
  ] : []
}
