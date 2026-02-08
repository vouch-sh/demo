# Workload Identity Pool groups external identities and lets you define
# which external tokens are accepted.
resource "google_iam_workload_identity_pool" "vouch" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "Vouch Identity Pool"
  description               = "Accepts OIDC tokens issued by Vouch for workload identity federation"
}

# OIDC provider within the pool — validates tokens from the Vouch issuer.
resource "google_iam_workload_identity_pool_provider" "vouch" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.vouch.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "Vouch OIDC"
  description                        = "OIDC identity provider for Vouch-authenticated workloads"

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.actor"      = "assertion.actor"
    "attribute.repository" = "assertion.repository"
  }

  oidc {
    issuer_uri        = var.vouch_issuer_url
    allowed_audiences = var.vouch_audiences
  }
}

# Service account that federated Vouch identities impersonate.
resource "google_service_account" "vouch" {
  project      = var.project_id
  account_id   = var.service_account_id
  display_name = "Vouch Demo Service Account"
  description  = "Service account for Vouch-authenticated workloads"
}

# Allow identities from the Vouch pool to impersonate this service account.
resource "google_service_account_iam_member" "vouch_workload_identity" {
  service_account_id = google_service_account.vouch.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.vouch.name}/*"
}

# Secure default: read-only viewer access at project level.
resource "google_project_iam_member" "vouch_viewer" {
  project = var.project_id
  role    = "roles/viewer"
  member  = "serviceAccount:${google_service_account.vouch.email}"
}
