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
- Fetches the CA public key directly from the Vouch instance (`us.vouch.sh` by default)
- Installs it to `/etc/ssh/vouch-ca.pub`
- Adds `TrustedUserCAKeys` to sshd config (via `sshd_config.d` drop-in)
- Configures `RevokedKeys` for certificate revocation
- Controls access by **domain** and/or **principal** via `AuthorizedPrincipalsCommand`

Re-running the playbook picks up any CA key rotations automatically.

### Access Control

The role supports two complementary ways to control who can SSH in:

**Domain-based** — accept any certificate whose principal matches `*@<domain>`:

```yaml
vouch_allowed_domains:
  - acme.com
  - contractor.acme.com
```

**Principal-based** — restrict which principals can log in as which local user:

```yaml
vouch_authorized_principals:
  root:
    - admin
  deploy:
    - deploy
    - ci
```

Both can be used together. When either is configured, sshd calls an `AuthorizedPrincipalsCommand` script at login time that extracts principals from the presented certificate, checks them against allowed domains, and also checks static per-user principal mappings.

### Usage

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/sshd-ca.yml
```

### Role Variables

| Name | Default | Description |
|------|---------|-------------|
| `vouch_instance_url` | `https://us.vouch.sh` | Base URL of the Vouch instance to fetch the CA key from |
| `vouch_ca_public_key_endpoint` | `/ssh/ca.pub` | Path to the CA public key endpoint |
| `vouch_ca_key_path` | `/etc/ssh/vouch-ca.pub` | Where to write the CA key on the host |
| `vouch_allowed_domains` | `[]` | Email domains allowed to SSH in (e.g. `["acme.com"]`) |
| `vouch_authorized_principals` | `{}` | Map of username to list of allowed principals |
| `vouch_revoked_keys_path` | `/etc/ssh/vouch-revoked-keys` | Path to the revoked keys file |
| `vouch_sshd_config_path` | `/etc/ssh/sshd_config.d/vouch-ca.conf` | sshd config drop-in path |
