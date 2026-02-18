# Vouch Demo

Terraform modules and an Ansible role for provisioning AWS demo resources to test [Vouch](https://github.com/vouch-sh) credential helpers. Deploy infrastructure, configure Vouch, and verify access to AWS services using OIDC-based workload identity.

## Prerequisites

- **Terraform** >= 1.5
- **AWS account** with admin access (for provisioning resources)
- **Vouch CLI** installed:

  **macOS:**
  ```bash
  brew install vouch-sh/tap/vouch
  brew services start vouch
  ```

  **Debian/Ubuntu:**
  ```bash
  curl -fsSL https://packages.vouch.sh/gpg | sudo gpg --dearmor -o /usr/share/keyrings/vouch-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/vouch-archive-keyring.gpg] https://packages.vouch.sh/apt stable main" | sudo tee /etc/apt/sources.list.d/vouch.list
  sudo apt update && sudo apt install vouch
  ```

  **Fedora:**
  ```bash
  sudo dnf config-manager --add-repo https://packages.vouch.sh/rpm/vouch.repo
  sudo dnf install vouch
  ```

- **YubiKey** or FIDO2 authenticator
- **kubectl** (if enabling EKS)
- **Docker** (if enabling ECR)
- **Session Manager plugin** (if enabling EC2) — [install guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## Quick Start

### 1. Authenticate with Vouch

```bash
vouch enroll --server https://us.vouch.sh   # one-time enrollment
vouch login                                  # daily — starts an 8-hour session
```

### 2. Deploy infrastructure

```bash
cd examples/complete
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to enable the services you want:

```hcl
vouch_issuer_url = "https://auth.vouch.sh"

codecommit_enabled   = true
codeartifact_enabled = true
ecr_enabled          = true
ec2_enabled          = true
# eks_enabled        = true   # ~$73/mo control plane
```

Then deploy:

```bash
terraform init
terraform apply
```

### 3. Configure Vouch for AWS

After `terraform apply`, copy and run the setup command from the output:

```bash
$(terraform output -raw vouch_setup_aws)
```

Verify it works:

```bash
aws sts get-caller-identity --profile vouch
```

## Using the Demo

Terraform outputs ready-to-run commands for each enabled service. Run `terraform output` to see all available commands.

### Git (CodeCommit)

```bash
# Setup (once)
$(terraform output -raw vouch_setup_codecommit)

# Clone and test
$(terraform output -raw codecommit_clone_command)
cd vouch-demo-repo
echo "hello" > test.txt && git add . && git commit -m "test" && git push
```

### Packages (CodeArtifact)

```bash
# Setup (once) — configures npm to use CodeArtifact via Vouch
$(terraform output -raw vouch_setup_codeartifact_npm)

# Install a package to verify
npm install lodash
```

### Container Registry (ECR)

```bash
# Setup (once)
$(terraform output -raw vouch_setup_docker)

# Push a test image
docker pull alpine:latest
docker tag alpine:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest
```

### EC2 (Session Manager)

No additional setup beyond the AWS profile. Requires the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).

```bash
$(terraform output -raw ssm_connect_command)
```

The instance has no inbound ports — all access is via SSM.

### Kubernetes (EKS)

```bash
# Setup (once) — updates kubeconfig
$(terraform output -raw vouch_setup_eks)

# Verify
kubectl get nodes
```

> **Cost warning:** EKS Auto Mode has a ~$73/mo control plane charge. Destroy when not in use.

## SSH Certificate Authentication

Vouch can issue short-lived SSH certificates. The client gets a certificate; the server trusts the Vouch CA.

### Client

```bash
vouch setup ssh
ssh user@host
```

### Server (Ansible)

The `ansible/roles/vouch_sshd` role configures `sshd` on target hosts to trust the Vouch SSH CA.

**1. Set up inventory:**

```bash
cp ansible/inventory/hosts.example ansible/inventory/hosts
# Edit ansible/inventory/hosts — add your target hosts
```

**2. Configure principals** in your playbook or group vars:

```yaml
vouch_authorized_principals:
  root:
    - admin
  deploy:
    - deploy
    - ci
```

With this config, only certs with the `admin` principal can SSH as `root`, and only `deploy` or `ci` principals can SSH as `deploy`.

**3. Run the playbook:**

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/sshd-ca.yml
```

Re-running the playbook picks up any CA key rotations automatically.

#### Role Variables

| Name | Default | Description |
|------|---------|-------------|
| `vouch_instance_url` | `https://us.vouch.sh` | Base URL of the Vouch instance |
| `vouch_ca_key_path` | `/etc/ssh/vouch-ca.pub` | Where to write the CA key on the host |
| `vouch_authorized_principals` | `{}` | Map of username to list of allowed principals |
| `vouch_revoked_keys_path` | `/etc/ssh/vouch-revoked-keys` | Path to the revoked keys file |
| `vouch_sshd_config_path` | `/etc/ssh/sshd_config.d/vouch-ca.conf` | sshd config drop-in path |

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vouch_issuer_url` | OIDC issuer URL for Vouch | `string` | — | yes |
| `name_prefix` | Prefix for resource names | `string` | `"vouch-demo"` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |
| `aws_enabled` | Deploy AWS identity resources | `bool` | `true` | no |
| `k8s_enabled` | Deploy Kubernetes resources | `bool` | `true` | no |
| `codecommit_enabled` | Create CodeCommit repository | `bool` | `false` | no |
| `codeartifact_enabled` | Create CodeArtifact domain and repository | `bool` | `false` | no |
| `ecr_enabled` | Create ECR repository | `bool` | `false` | no |
| `ec2_enabled` | Create EC2 instance with SSM | `bool` | `false` | no |
| `eks_enabled` | Create EKS Auto Mode cluster | `bool` | `false` | no |

## Outputs

### Resource outputs

| Name | Description |
|------|-------------|
| `aws_oidc_provider_arn` | ARN of the AWS IAM OIDC provider |
| `aws_role_arn` | ARN of the IAM role for Vouch workloads |
| `k8s_namespace` | Kubernetes namespace |
| `k8s_service_account_name` | Kubernetes service account name |
| `codecommit_clone_url_http` | HTTP clone URL for CodeCommit |
| `codecommit_clone_url_ssh` | SSH clone URL for CodeCommit |
| `codeartifact_domain_name` | CodeArtifact domain name |
| `codeartifact_repository_name` | CodeArtifact repository name |
| `codeartifact_domain_owner` | AWS account ID owning the domain |
| `ecr_repository_url` | ECR repository URL |
| `ec2_instance_id` | EC2 instance ID |
| `ec2_instance_public_ip` | EC2 instance public IP |
| `eks_cluster_name` | EKS cluster name |
| `eks_cluster_endpoint` | EKS cluster endpoint URL |
| `eks_cluster_certificate_authority` | EKS cluster CA (base64) |

### Command outputs

| Name | Description |
|------|-------------|
| `vouch_setup_aws` | Configure Vouch for AWS |
| `vouch_setup_codecommit` | Configure Vouch for CodeCommit |
| `vouch_setup_codeartifact_npm` | Configure Vouch for CodeArtifact (npm) |
| `vouch_setup_docker` | Configure Vouch for ECR |
| `vouch_setup_eks` | Configure kubectl for EKS |
| `codecommit_clone_command` | Clone the CodeCommit repository |
| `ssm_connect_command` | Start an SSM session on the EC2 instance |

## Cost Estimates

| Resource | Cost |
|----------|------|
| VPC (no NAT) | $0 |
| CodeCommit | $0 |
| CodeArtifact | ~$0 |
| ECR | $0 |
| EC2 t2.nano | ~$4 |
| EKS control plane | ~$73 |
| EKS Auto Mode compute | pay-per-use |
| **Total (all on)** | **~$77/mo + EKS compute** |
| **Total (no EKS)** | **~$4/mo** |

All demo service modules default to disabled.

## Cleanup

```bash
cd examples/complete
terraform destroy
```
