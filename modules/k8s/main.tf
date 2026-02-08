resource "kubernetes_namespace" "vouch" {
  metadata {
    name = var.namespace

    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/part-of"    = "vouch"
    }
  }
}

# Service account for workloads that authenticate via Vouch.
# Annotations bind this SA to cloud provider identities:
#   - AWS: eks.amazonaws.com/role-arn for IRSA
#   - GCP: iam.gke.io/gcp-service-account for Workload Identity
resource "kubernetes_service_account" "vouch" {
  metadata {
    name      = "vouch"
    namespace = kubernetes_namespace.vouch.metadata[0].name

    annotations = merge(
      var.aws_role_arn != "" ? {
        "eks.amazonaws.com/role-arn" = var.aws_role_arn
      } : {},
      var.gcp_service_account != "" ? {
        "iam.gke.io/gcp-service-account" = var.gcp_service_account
      } : {},
    )

    labels = {
      "app.kubernetes.io/name"       = "vouch"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

# ClusterRole granting Vouch the permissions it needs to verify and
# manage workload identities across the cluster.
resource "kubernetes_cluster_role" "vouch" {
  metadata {
    name = "vouch"

    labels = {
      "app.kubernetes.io/name"       = "vouch"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Read service accounts and tokens for identity verification
  rule {
    api_groups = [""]
    resources  = ["serviceaccounts", "serviceaccounts/token"]
    verbs      = ["get", "list", "watch", "create"]
  }

  # Read pods and namespaces for workload discovery
  rule {
    api_groups = [""]
    resources  = ["pods", "namespaces"]
    verbs      = ["get", "list", "watch"]
  }

  # TokenReview for validating service account tokens
  rule {
    api_groups = ["authentication.k8s.io"]
    resources  = ["tokenreviews"]
    verbs      = ["create"]
  }

  # SubjectAccessReview for authorization checks
  rule {
    api_groups = ["authorization.k8s.io"]
    resources  = ["subjectaccessreviews"]
    verbs      = ["create"]
  }
}

resource "kubernetes_cluster_role_binding" "vouch" {
  metadata {
    name = "vouch"

    labels = {
      "app.kubernetes.io/name"       = "vouch"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.vouch.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.vouch.metadata[0].name
    namespace = kubernetes_namespace.vouch.metadata[0].name
  }
}

# ConfigMap with Vouch configuration that workloads can mount.
resource "kubernetes_config_map" "vouch" {
  metadata {
    name      = "vouch-config"
    namespace = kubernetes_namespace.vouch.metadata[0].name

    labels = {
      "app.kubernetes.io/name"       = "vouch"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    "vouch.yaml" = yamlencode({
      issuer    = var.vouch_issuer_url
      audiences = var.vouch_audiences
    })
  }
}
