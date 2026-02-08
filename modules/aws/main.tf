data "tls_certificate" "vouch" {
  url = var.vouch_issuer_url
}

# The OIDC provider allows AWS STS to validate tokens issued by Vouch.
# Workloads presenting a valid Vouch-issued OIDC token can use
# sts:AssumeRoleWithWebIdentity to obtain temporary AWS credentials.
resource "aws_iam_openid_connect_provider" "vouch" {
  url             = var.vouch_issuer_url
  client_id_list  = var.vouch_audiences
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

data "aws_iam_policy_document" "trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.vouch.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(var.vouch_issuer_url, "https://", "")}:aud"
      values   = var.vouch_audiences
    }
  }
}

# Secure default: read-only access.
resource "aws_iam_role_policy_attachment" "readonly" {
  role       = aws_iam_role.vouch.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}
