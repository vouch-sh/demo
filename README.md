# Vouch Demo

Server-side configuration needed to integrate with [Vouch](https://github.com/vouch-sh). Includes Terraform modules for OIDC-based workload identity federation across cloud providers, and an Ansible role for configuring SSH certificate authentication.

## Terraform Modules

### `modules/aws`

Creates an AWS IAM OIDC provider pointing at the Vouch issuer and an IAM role with a trust policy that accepts Vouch-issued tokens. Attaches `ReadOnlyAccess` by default.

**Resources created:**
- `aws_iam_openid_connect_provider` — validates Vouch OIDC tokens
- `aws_iam_role` — assumable via `sts:AssumeRoleWithWebIdentity`
- `aws_iam_role_policy_attachment` — read-only access (default)

### `modules/gcp`

Creates a GCP Workload Identity Pool and OIDC provider that trusts the Vouch issuer, plus a service account that federated identities can impersonate. Grants `roles/viewer` by default.

**Resources created:**
- `google_iam_workload_identity_pool` — groups Vouch identities
- `google_iam_workload_identity_pool_provider` — OIDC provider
- `google_service_account` — impersonated by Vouch workloads
- `google_service_account_iam_member` — workload identity binding
- `google_project_iam_member` — viewer role (default)

### `modules/k8s`

Creates a Kubernetes namespace, service account (annotated for AWS IRSA and GCP Workload Identity), RBAC rules for identity verification, and a ConfigMap with Vouch configuration.

**Resources created:**
- `kubernetes_namespace`
- `kubernetes_service_account` — with cloud provider annotations
- `kubernetes_cluster_role` / `kubernetes_cluster_role_binding` — token review and workload discovery
- `kubernetes_config_map` — Vouch issuer/audience config

## Quick Start

```hcl
module "vouch_demo" {
  source = "github.com/vouch-sh/demo"

  vouch_issuer_url = "https://auth.vouch.sh"
  gcp_project_id   = "my-project"
}
```

To deploy only specific providers:

```hcl
module "vouch_demo" {
  source = "github.com/vouch-sh/demo"

  vouch_issuer_url = "https://auth.vouch.sh"

  aws_enabled = true
  gcp_enabled = false
  k8s_enabled = false
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vouch_issuer_url` | OIDC issuer URL for Vouch | `string` | — | yes |
| `aws_enabled` | Deploy AWS resources | `bool` | `true` | no |
| `gcp_enabled` | Deploy GCP resources | `bool` | `true` | no |
| `gcp_project_id` | GCP project ID | `string` | `""` | when `gcp_enabled` |
| `k8s_enabled` | Deploy Kubernetes resources | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| `aws_oidc_provider_arn` | ARN of the AWS IAM OIDC provider |
| `aws_role_arn` | ARN of the IAM role for Vouch workloads |
| `gcp_workload_identity_pool_name` | Full name of the GCP Workload Identity Pool |
| `gcp_workload_identity_provider_name` | Full name of the OIDC provider |
| `gcp_service_account_email` | Email of the GCP service account |
| `k8s_namespace` | Kubernetes namespace |
| `k8s_service_account_name` | Kubernetes service account name |

## Provider Requirements

| Provider | Version |
|----------|---------|
| `hashicorp/aws` | `~> 6.31` |
| `hashicorp/google` | `>= 6.0` |
| `hashicorp/kubernetes` | `>= 2.25` |
| Terraform | `>= 1.5` |

## Security Defaults

All modules follow the principle of least privilege:

- **AWS**: Role gets `ReadOnlyAccess` only. Override by attaching additional policies outside the module.
- **GCP**: Service account gets `roles/viewer` only. Grant additional roles as needed.
- **Kubernetes**: ClusterRole is scoped to token review, service account reads, and pod/namespace discovery.

## Ansible

### `ansible/roles/vouch_sshd`

Configures `sshd` on target hosts to trust the Vouch SSH CA, enabling certificate-based authentication. Users with a Vouch-signed SSH certificate can authenticate without individual public keys in `authorized_keys`.

**What it does:**
- Fetches the Vouch CA public key from `us.vouch.sh/ssh/ca.pub`
- Installs it to `/etc/ssh/vouch-ca.pub` and adds `TrustedUserCAKeys` via `sshd_config.d` drop-in
- Configures `RevokedKeys` for certificate revocation
- Uses `AuthorizedPrincipalsFile` to control which cert principals can log in as which local user

Re-running the playbook picks up any CA key rotations automatically.

### Access Control

Use `vouch_authorized_principals` to control which certificate principals can log in as which local user. sshd only allows a certificate if its principal appears in the file for the target username:

```yaml
vouch_authorized_principals:
  root:
    - admin
  deploy:
    - deploy
    - ci
```

With this config, only certs containing the `admin` principal can SSH in as `root`, and only `deploy` or `ci` principals can SSH in as `deploy`.

### Usage

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/sshd-ca.yml
```

### Role Variables

| Name | Default | Description |
|------|---------|-------------|
| `vouch_instance_url` | `https://us.vouch.sh` | Base URL of the Vouch instance |
| `vouch_ca_key_path` | `/etc/ssh/vouch-ca.pub` | Where to write the CA key on the host |
| `vouch_authorized_principals` | `{}` | Map of username to list of allowed principals |
| `vouch_revoked_keys_path` | `/etc/ssh/vouch-revoked-keys` | Path to the revoked keys file |
| `vouch_sshd_config_path` | `/etc/ssh/sshd_config.d/vouch-ca.conf` | sshd config drop-in path |
