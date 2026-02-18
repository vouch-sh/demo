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

# Additional permissions for demo services (CodeCommit, CodeArtifact, ECR, SSM, EKS, Bedrock).
# Only attached when at least one demo service module is enabled.
resource "aws_iam_role_policy" "demo_services" {
  count = var.demo_services_enabled ? 1 : 0

  name   = "${var.role_name}-demo-services"
  role   = aws_iam_role.vouch.id
  policy = data.aws_iam_policy_document.demo_services.json
}

data "aws_iam_policy_document" "demo_services" {
  statement {
    sid    = "CodeCommit"
    effect = "Allow"
    actions = [
      "codecommit:GitPull",
      "codecommit:GitPush",
      "codecommit:GetRepository",
      "codecommit:ListRepositories",
    ]
    resources = var.codecommit_repository_arn != "" ? [var.codecommit_repository_arn] : ["*"]
  }

  statement {
    sid    = "CodeArtifact"
    effect = "Allow"
    actions = [
      "codeartifact:GetAuthorizationToken",
      "codeartifact:GetRepositoryEndpoint",
      "codeartifact:ReadFromRepository",
      "codeartifact:PublishPackageVersion",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CodeArtifactSTS"
    effect = "Allow"
    actions = [
      "sts:GetServiceBearerToken",
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "sts:AWSServiceName"
      values   = ["codeartifact.amazonaws.com"]
    }
  }

  statement {
    sid    = "ECR"
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "SSM"
    effect = "Allow"
    actions = [
      "ssm:StartSession",
      "ssm:TerminateSession",
      "ssm:ResumeSession",
      "ssm:DescribeSessions",
      "ssm:GetConnectionStatus",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "EKS"
    effect = "Allow"
    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Bedrock"
    effect = "Allow"
    actions = [
      "bedrock:InvokeModel",
      "bedrock:InvokeModelWithResponseStream",
      "bedrock:ListFoundationModels",
    ]
    resources = ["*"]
  }
}
