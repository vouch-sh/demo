resource "aws_codeartifact_domain" "this" {
  domain = var.name_prefix

  tags = var.tags
}

# Upstream repository with external connection to public npmjs
resource "aws_codeartifact_repository" "upstream" {
  repository = "${var.name_prefix}-upstream"
  domain     = aws_codeartifact_domain.this.domain

  external_connections {
    external_connection_name = "public:npmjs"
  }

  tags = var.tags
}

resource "aws_codeartifact_repository" "this" {
  repository = var.name_prefix
  domain     = aws_codeartifact_domain.this.domain

  upstream {
    repository_name = aws_codeartifact_repository.upstream.repository
  }

  tags = var.tags
}
