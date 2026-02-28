# The OIDC provider allows AWS STS to validate tokens issued by Vouch.
# Workloads presenting a valid Vouch-issued OIDC token can use
# sts:AssumeRoleWithWebIdentity to obtain temporary AWS credentials.
resource "aws_iam_openid_connect_provider" "vouch" {
  url             = var.vouch_issuer_url
  client_id_list  = [var.vouch_issuer_url]
  thumbprint_list = [data.tls_certificate.vouch.certificates[0].sha1_fingerprint]

  tags = var.tags
}

# IAM role that Vouch-authenticated workloads can assume.
# Trust policy restricts access to the matching OIDC audience.
resource "aws_iam_role" "vouch" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = var.tags
}

# Secure default: read-only access.
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.vouch.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/ReadOnlyAccess"
}

# Additional permissions for demo services (CodeCommit, CodeArtifact, ECR, SSM, EKS, Bedrock).
# Only attached when at least one demo service module is enabled.
resource "aws_iam_role_policy" "demo_services" {
  count = var.demo_services_enabled ? 1 : 0

  name   = "${var.role_name}-demo-services"
  role   = aws_iam_role.vouch.id
  policy = data.aws_iam_policy_document.demo_services.json
}
