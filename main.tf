module "aws" {
  count  = var.aws_enabled ? 1 : 0
  source = "./modules/aws"

  vouch_issuer_url = var.vouch_issuer_url

  demo_services_enabled     = local.demo_services_enabled
  codecommit_repository_arn = var.codecommit_enabled ? one(module.aws_codecommit[*].arn) : ""

  tags = var.tags
}

module "aws_vpc" {
  count  = local.vpc_needed ? 1 : 0
  source = "./modules/aws-vpc"

  name_prefix = var.name_prefix
  tags        = var.tags
}

module "aws_codecommit" {
  count  = var.codecommit_enabled ? 1 : 0
  source = "./modules/aws-codecommit"

  name_prefix = var.name_prefix
  tags        = var.tags
}

module "aws_codeartifact" {
  count  = var.codeartifact_enabled ? 1 : 0
  source = "./modules/aws-codeartifact"

  name_prefix = var.name_prefix
  tags        = var.tags
}

module "aws_ecr" {
  count  = var.ecr_enabled ? 1 : 0
  source = "./modules/aws-ecr"

  name_prefix = var.name_prefix
  tags        = var.tags
}

module "aws_ec2" {
  count  = var.ec2_enabled ? 1 : 0
  source = "./modules/aws-ec2"

  name_prefix               = var.name_prefix
  subnet_id                 = one(module.aws_vpc[*].public_subnet_ids)[0]
  vpc_id                    = one(module.aws_vpc[*].vpc_id)
  vouch_issuer_url          = var.vouch_issuer_url
  ssh_authorized_principals = local.ssh_authorized_principals
  tags                      = var.tags
}

module "aws_eks" {
  count  = var.eks_enabled ? 1 : 0
  source = "./modules/aws-eks"

  name_prefix         = var.name_prefix
  subnet_ids          = one(module.aws_vpc[*].public_subnet_ids)
  vouch_role_arn      = var.aws_enabled ? one(module.aws[*].role_arn) : ""
  create_access_entry = var.aws_enabled
  tags                = var.tags
}

module "aws_rds" {
  count  = var.rds_enabled ? 1 : 0
  source = "./modules/aws-rds"

  name_prefix = var.name_prefix
  vpc_id      = one(module.aws_vpc[*].vpc_id)
  subnet_ids  = one(module.aws_vpc[*].public_subnet_ids)
  tags        = var.tags
}

module "aws_redshift_serverless" {
  count  = var.redshift_serverless_enabled ? 1 : 0
  source = "./modules/aws-redshift-serverless"

  name_prefix = var.name_prefix
  vpc_id      = one(module.aws_vpc[*].vpc_id)
  subnet_ids  = one(module.aws_vpc[*].public_subnet_ids)
  tags        = var.tags
}
