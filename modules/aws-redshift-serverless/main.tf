resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-redshift-"
  description = "Security group for Vouch demo Redshift Serverless workgroup"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow Redshift access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-redshift"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "aws_redshiftserverless_namespace" "this" {
  namespace_name = "${var.name_prefix}-redshift"

  db_name            = "vouch"
  admin_username     = "vouchadmin"
  admin_user_password = random_password.admin.result

  tags = var.tags
}

resource "aws_redshiftserverless_workgroup" "this" {
  workgroup_name = "${var.name_prefix}-redshift"
  namespace_name = aws_redshiftserverless_namespace.this.namespace_name

  base_capacity      = 8
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.this.id]

  publicly_accessible = true

  tags = var.tags
}
