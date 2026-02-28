# IAM role for the EKS cluster control plane
resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.${local.aws_dns_suffix}"
      }
      Action = [
        "sts:AssumeRole",
        "sts:TagSession",
      ]
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_compute" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSComputePolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_block_storage" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSBlockStoragePolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_load_balancing" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_networking" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSNetworkingPolicy"
}

# IAM role for Auto Mode managed nodes
resource "aws_iam_role" "node" {
  name = "${var.name_prefix}-eks-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.${local.aws_dns_suffix}"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "node_minimal" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  role       = aws_iam_role.node.name
  policy_arn = "arn:${local.aws_partition}:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}

# EKS cluster with Auto Mode
resource "aws_eks_cluster" "this" {
  name     = "${var.name_prefix}-eks"
  role_arn = aws_iam_role.cluster.arn

  access_config {
    authentication_mode = "API"
  }

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose"]
    node_role_arn = aws_iam_role.node.arn
  }

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_public_access  = true
    endpoint_private_access = false
  }

  tags = var.tags

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy,
    aws_iam_role_policy_attachment.cluster_compute,
    aws_iam_role_policy_attachment.cluster_block_storage,
    aws_iam_role_policy_attachment.cluster_load_balancing,
    aws_iam_role_policy_attachment.cluster_networking,
  ]
}

# Grant the Terraform executor cluster admin access
resource "aws_eks_access_entry" "terraform" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "terraform" {
  cluster_name  = aws_eks_cluster.this.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  policy_arn    = "arn:${local.aws_partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.terraform]
}

# EKS access entries have eventual consistency — the Kubernetes API server
# may not recognize the new entry for several seconds after creation.
resource "time_sleep" "wait_for_access_entries" {
  depends_on = [
    aws_eks_access_policy_association.terraform,
    aws_eks_access_policy_association.vouch,
  ]

  create_duration = "15s"
}

# Grant the Vouch IAM role cluster admin access via EKS Access Entries
resource "aws_eks_access_entry" "vouch" {
  count = var.create_access_entry ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.vouch_role_arn
  type          = "STANDARD"

  tags = var.tags
}

resource "aws_eks_access_policy_association" "vouch" {
  count = var.create_access_entry ? 1 : 0

  cluster_name  = aws_eks_cluster.this.name
  principal_arn = var.vouch_role_arn
  policy_arn    = "arn:${local.aws_partition}:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.vouch]
}
