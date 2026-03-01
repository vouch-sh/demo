resource "aws_db_subnet_group" "this" {
  name       = "${var.name_prefix}-rds"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
  })
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "Security group for Vouch demo RDS instance - PostgreSQL access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow PostgreSQL access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "random_password" "master" {
  length  = 32
  special = false
}

resource "aws_db_instance" "this" {
  identifier = "${var.name_prefix}-rds"

  engine         = "postgres"
  engine_version = "17"
  instance_class = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"

  db_name  = "vouch"
  username = "vouchadmin"
  password = random_password.master.result

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  iam_database_authentication_enabled = true
  publicly_accessible                 = true

  multi_az            = false
  skip_final_snapshot = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds"
  })
}

resource "terraform_data" "bootstrap_iam_user" {
  triggers_replace = [aws_db_instance.this.id]

  provisioner "local-exec" {
    command = <<-EOT
      PGPASSWORD='${random_password.master.result}' psql \
        -h '${aws_db_instance.this.address}' \
        -p '${aws_db_instance.this.port}' \
        -U '${aws_db_instance.this.username}' \
        -d '${aws_db_instance.this.db_name}' \
        -c "DO \$\$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'vouch') THEN CREATE ROLE vouch WITH LOGIN; END IF; END \$\$; GRANT rds_iam TO vouch;"
    EOT
  }
}
