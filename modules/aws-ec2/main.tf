data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_iam_role" "ssm" {
  name = "${var.name_prefix}-ec2-ssm"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-ec2"
  role = aws_iam_role.ssm.name

  tags = var.tags
}

resource "aws_security_group" "this" {
  name_prefix = "${var.name_prefix}-ec2-"
  description = "Security group for Vouch demo EC2 instance - SSH and SSM access"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow SSH access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2"
  })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_instance" "this" {
  ami                    = data.aws_ami.al2023.id
  instance_type          = "t2.nano"
  subnet_id              = var.subnet_id
  iam_instance_profile   = aws_iam_instance_profile.this.name
  vpc_security_group_ids = [aws_security_group.this.id]

  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2
  }

  user_data = <<-EOF
    #!/bin/bash
    set -euo pipefail

    # Fetch Vouch SSH CA public key
    curl -fsSL "${var.vouch_issuer_url}/ssh/ca.pub" -o /etc/ssh/vouch-ca.pub

    # Create empty revoked keys file
    touch /etc/ssh/vouch-revoked-keys

    # Configure sshd to trust Vouch CA
    cat > /etc/ssh/sshd_config.d/vouch-ca.conf <<'SSHD'
    TrustedUserCAKeys /etc/ssh/vouch-ca.pub
    RevokedKeys /etc/ssh/vouch-revoked-keys
    SSHD

    # Restart sshd to pick up new config
    systemctl restart sshd
  EOF

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-ec2"
  })
}
