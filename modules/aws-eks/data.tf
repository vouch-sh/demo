data "aws_partition" "current" {}

# Resolve the current caller's IAM role ARN (handles SSO/assumed-role sessions)
data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
