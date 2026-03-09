resource "aws_codeartifact_domain" "this" {
  domain = var.name_prefix

  tags = var.tags
}

resource "aws_codeartifact_repository" "npm_store" {
  repository  = "npm-store"
  domain      = aws_codeartifact_domain.this.domain
  description = "Public repository mirror of npmjs"

  external_connections {
    external_connection_name = "public:npmjs"
  }

  tags = var.tags
}

resource "aws_codeartifact_repository" "pypi_store" {
  repository  = "pypi-store"
  domain      = aws_codeartifact_domain.this.domain
  description = "Public repository mirror of PyPI"

  external_connections {
    external_connection_name = "public:pypi"
  }

  tags = var.tags
}

resource "aws_codeartifact_repository" "this" {
  repository  = var.name_prefix
  domain      = aws_codeartifact_domain.this.domain
  description = "Internal package repository with npm and PyPI upstreams"

  upstream {
    repository_name = aws_codeartifact_repository.npm_store.repository
  }

  upstream {
    repository_name = aws_codeartifact_repository.pypi_store.repository
  }

  tags = var.tags
}
