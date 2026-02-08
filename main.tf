module "aws" {
  count  = var.aws_enabled ? 1 : 0
  source = "./modules/aws"

  vouch_issuer_url = var.vouch_issuer_url
}

module "gcp" {
  count  = var.gcp_enabled ? 1 : 0
  source = "./modules/gcp"

  vouch_issuer_url = var.vouch_issuer_url
  project_id       = var.gcp_project_id
}

module "k8s" {
  count  = var.k8s_enabled ? 1 : 0
  source = "./modules/k8s"

  vouch_issuer_url    = var.vouch_issuer_url
  aws_role_arn        = var.aws_enabled ? module.aws[0].role_arn : ""
  gcp_service_account = var.gcp_enabled ? module.gcp[0].service_account_email : ""
}
