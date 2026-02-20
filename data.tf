data "aws_region" "current" {}

data "external" "vouch_identity" {
  count   = var.ec2_enabled ? 1 : 0
  program = ["bash", "-c", "vouch status --json | jq '{email: .email}'"]
}
