# Vouch Demo

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D%201.10-7B42BC?logo=terraform)](https://www.terraform.io/)
[![AWS Provider](https://img.shields.io/badge/AWS_Provider-%3E%3D%206.0-FF9900?logo=amazonaws)](https://registry.terraform.io/providers/hashicorp/aws/latest)

This tutorial walks you through using [Vouch](https://github.com/vouch-sh) to authenticate to AWS services with OIDC-based workload identity. You'll deploy demo infrastructure with Terraform, then use Vouch credentials to push code, install packages, push container images, connect to servers, and access Kubernetes clusters — all without long-lived AWS credentials.

## Table of Contents

- [Architecture](#architecture)
- [Inputs](#inputs)
- [What You'll Need](#what-youll-need)
- [Step 1: Enroll with Vouch](#step-1-enroll-with-vouch)
- [Step 2: Deploy the Infrastructure](#step-2-deploy-the-infrastructure)
- [Step 3: Configure AWS Access](#step-3-configure-aws-access)
- [Step 4: Push Code with Git (CodeCommit)](#step-4-push-code-with-git-codecommit)
- [Step 5: Install Packages (CodeArtifact)](#step-5-install-packages-codeartifact)
- [Step 6: Push a Container Image (ECR)](#step-6-push-a-container-image-ecr)
- [Step 7: Connect to a Server (EC2 + Session Manager)](#step-7-connect-to-a-server-ec2--session-manager)
- [Step 8: Connect to a Database (RDS)](#step-8-connect-to-a-database-rds)
- [Step 9: Query a Data Warehouse (Redshift Serverless)](#step-9-query-a-data-warehouse-redshift-serverless)
- [Step 10: Access Kubernetes (EKS)](#step-10-access-kubernetes-eks)
- [Step 11: SSH with Certificates](#step-11-ssh-with-certificates)
- [Cleanup](#cleanup)
- [License](#license)

## Architecture

The root Terraform module is a composition layer that wires together independent sub-modules. Each service is toggled via `*_enabled` boolean variables and defaults to `false` to minimize cost.

| Module | Description | Default |
|--------|-------------|---------|
| `modules/aws` | IAM OIDC provider + Vouch role with trust policy | Enabled |
| `modules/k8s` | Kubernetes namespace, ServiceAccount (IRSA), RBAC | Enabled |
| `modules/aws-vpc` | VPC, subnets, IGW (auto-created when EC2/EKS/RDS/Redshift needed) | Auto |
| `modules/aws-codecommit` | CodeCommit Git repository | Disabled |
| `modules/aws-codeartifact` | CodeArtifact domain + npm/PyPI repositories | Disabled |
| `modules/aws-ecr` | ECR container image repository | Disabled |
| `modules/aws-ec2` | EC2 instance with SSM + SSH certificate support | Disabled |
| `modules/aws-eks` | EKS Auto Mode cluster with Access Entries | Disabled |
| `modules/aws-rds` | RDS PostgreSQL with IAM authentication | Disabled |
| `modules/aws-redshift-serverless` | Redshift Serverless with IAM authentication | Disabled |

The root module passes outputs between sub-modules — VPC outputs flow into EC2/EKS/RDS/Redshift, the Vouch IAM role ARN flows into EKS for Access Entries, and service ARNs flow back to scope IAM policies.

An independent [Ansible role](#step-11-ssh-with-certificates) (`ansible/roles/vouch_sshd`) configures SSH certificate authentication on target hosts.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `vouch_issuer_url` | OIDC issuer URL for Vouch (e.g. `https://us.vouch.sh`) | `string` | — | Yes |
| `name_prefix` | Prefix for resource names | `string` | `"vouch-demo"` | No |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | No |
| `aws_enabled` | Deploy AWS Vouch integration (IAM OIDC + role) | `bool` | `true` | No |
| `codecommit_enabled` | Create a CodeCommit repository | `bool` | `false` | No |
| `codeartifact_enabled` | Create CodeArtifact domain and repository | `bool` | `false` | No |
| `ecr_enabled` | Create an ECR repository | `bool` | `false` | No |
| `ec2_enabled` | Create an EC2 instance with SSM access | `bool` | `false` | No |
| `eks_enabled` | Create an EKS Auto Mode cluster | `bool` | `false` | No |
| `rds_enabled` | Create an RDS PostgreSQL instance with IAM auth | `bool` | `false` | No |
| `redshift_serverless_enabled` | Create a Redshift Serverless workgroup with IAM auth | `bool` | `false` | No |

## What You'll Need

### Requirements

| Provider | Version |
|----------|---------|
| [Terraform](https://www.terraform.io/) | >= 1.10 |
| [hashicorp/aws](https://registry.terraform.io/providers/hashicorp/aws/latest) | >= 6.0 |
| [hashicorp/tls](https://registry.terraform.io/providers/hashicorp/tls/latest) | >= 4.0 |
| [hashicorp/time](https://registry.terraform.io/providers/hashicorp/time/latest) | >= 0.12 |
| [hashicorp/cloudinit](https://registry.terraform.io/providers/hashicorp/cloudinit/latest) | >= 2.3 |
| [hashicorp/random](https://registry.terraform.io/providers/hashicorp/random/latest) | >= 3.6 |
| [hashicorp/external](https://registry.terraform.io/providers/hashicorp/external/latest) | >= 2.3 |

### Tools

- **AWS account** with admin access
- **YubiKey** or FIDO2 authenticator
- **Vouch CLI** — install for your platform:

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

Depending on which services you enable, you may also need:

- **kubectl** — for EKS
- **Docker** — for ECR
- **psql** — for RDS and Redshift Serverless
- **Session Manager plugin** — for EC2 ([install guide](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html))

## Step 1: Enroll with Vouch

If this is your first time using Vouch, enroll your authenticator:

```bash
vouch enroll --server https://us.vouch.sh
```

Then start a session:

```bash
vouch login
```

Sessions last 8 hours. Run `vouch login` again when your session expires.

## Step 2: Deploy the Infrastructure

Clone this repository and navigate to the example configuration:

```bash
git clone https://github.com/vouch-sh/vouch-demo.git
cd vouch-demo/examples/complete
```

Copy the example variables file and edit it to enable the services you want:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Open `terraform.tfvars` and uncomment the services you'd like to try:

```hcl
vouch_issuer_url = "https://us.vouch.sh"

codecommit_enabled   = true
codeartifact_enabled = true
ecr_enabled          = true
ec2_enabled          = true
# eks_enabled                = true  # ~$73/mo control plane — uncomment if needed
# rds_enabled                = true  # ~$12/mo db.t4g.micro — uncomment if needed
# redshift_serverless_enabled = true  # pay-per-query — uncomment if needed
```

Deploy:

```bash
terraform init
terraform apply
```

**Cost estimates** (all services default to disabled — you only pay for what you turn on):

| Service | Approximate Cost | Notes |
|---------|-----------------|-------|
| CodeCommit, CodeArtifact, ECR | $0 | Free tier / negligible |
| EC2 | ~$4/mo | t2.nano |
| RDS | ~$12/mo | db.t4g.micro PostgreSQL |
| Redshift Serverless | ~$4/hr when active | Pay-per-query, $0 when idle |
| EKS | ~$73/mo | Control plane charge |

## Step 3: Configure AWS Access

After `terraform apply` completes, run the setup command it outputs. This tells Vouch which IAM role to assume:

```bash
$(terraform output -raw vouch_setup_aws)
```

Verify it works:

```bash
aws sts get-caller-identity --profile vouch
```

You should see the Vouch IAM role ARN in the output. Behind the scenes, this created an IAM OIDC provider that trusts your Vouch issuer and an IAM role with a trust policy scoped to your Vouch identity.

## Step 4: Push Code with Git (CodeCommit)

*Requires `codecommit_enabled = true`.*

Configure Vouch as a Git credential helper:

```bash
$(terraform output -raw vouch_setup_codecommit)
```

Clone the demo repository:

```bash
$(terraform output -raw codecommit_clone_command)
```

Push a test commit:

```bash
cd vouch-demo
echo "hello from vouch" > test.txt
git add .
git commit -m "test push"
git push
```

## Step 5: Install Packages (CodeArtifact)

*Requires `codeartifact_enabled = true`.*

CodeArtifact proxies packages from public registries (npmjs and PyPI) through your AWS account. Configure one or more package managers below.

### npm

Configure npm to use CodeArtifact through Vouch:

```bash
$(terraform output -raw vouch_setup_codeartifact_npm)
```

Verify npm is pointing at your CodeArtifact repository:

```bash
npm config get registry
```

Install a package to verify:

```bash
npm install lodash
```

### pnpm

pnpm reads the same npm registry configuration, so after running the npm setup above:

```bash
pnpm config get registry
```

Install a package to verify:

```bash
pnpm add lodash
```

### pip

Configure pip to use CodeArtifact through Vouch:

```bash
$(terraform output -raw vouch_setup_codeartifact_pip)
```

Verify pip is pointing at your CodeArtifact repository:

```bash
pip config get global.index-url
```

Install a package to verify:

```bash
pip install requests
```

### uv

uv reads the same pip index configuration, so after running the pip setup above:

```bash
uv pip install requests
```

All package managers fetch packages from your CodeArtifact repository, authenticating with Vouch credentials.

## Step 6: Push a Container Image (ECR)

*Requires `ecr_enabled = true` and Docker running.*

Configure Docker to authenticate to ECR through Vouch:

```bash
$(terraform output -raw vouch_setup_docker)
```

Pull, tag, and push a test image:

```bash
docker pull alpine:latest
docker tag alpine:latest $(terraform output -raw ecr_repository_url):latest
docker push $(terraform output -raw ecr_repository_url):latest
```

## Step 7: Connect to a Server (EC2 + Session Manager)

*Requires `ec2_enabled = true` and the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html).*

Start an SSM session:

```bash
$(terraform output -raw ssm_connect_command)
```

The instance has zero inbound security group rules — all access is through SSM using your Vouch AWS profile.

## Step 8: Connect to a Database (RDS)

*Requires `rds_enabled = true` and psql installed.*

Connect to the RDS instance using a Vouch IAM auth token as the password:

```bash
$(terraform output -raw rds_connect_command)
```

Verify you're connected as the IAM-authenticated user:

```sql
SELECT current_user;
```

This should return `vouch`. Behind the scenes, Vouch generates a 15-minute IAM authentication token that RDS accepts as the PostgreSQL password over a TLS connection (`sslmode=require`). The token is scoped to the specific database instance and user.

## Step 9: Query a Data Warehouse (Redshift Serverless)

*Requires `redshift_serverless_enabled = true` and psql installed.*

Connect to the Redshift Serverless workgroup using Vouch IAM credentials:

```bash
$(terraform output -raw redshift_connect_command)
```

Verify you're connected:

```sql
SELECT current_user;
```

This returns an IAM-mapped user like `IAMR:vouch-demo`. Behind the scenes, `vouch exec --type redshift` exchanges your Vouch session for temporary Redshift credentials via the `GetCredentials` API, then injects `PGPASSWORD`, `PGUSER`, and `PGSSLMODE` into the psql environment.

Redshift Serverless charges per RPU-hour (~$4/hour at 8 RPUs) only when queries are running. Destroy when not in use to avoid charges.

## Step 10: Access Kubernetes (EKS)

*Requires `eks_enabled = true` and kubectl installed.*

> **Cost warning:** EKS Auto Mode has a ~$73/mo control plane charge. Destroy when not in use.

Configure kubectl to use Vouch for EKS authentication:

```bash
$(terraform output -raw vouch_setup_eks)
```

Verify access:

```bash
kubectl cluster-info
kubectl auth whoami
```

EKS Auto Mode provisions nodes on-demand, so `kubectl get nodes` will be empty until you schedule a workload.

The Terraform module creates an EKS Access Entry that maps your Vouch IAM role to cluster admin, so kubectl works immediately.

## Step 11: SSH with Certificates

Vouch can issue short-lived SSH certificates. The client gets a certificate signed by the Vouch CA; the server is configured to trust that CA.

*Requires `ec2_enabled = true`.*

### Client Setup

Configure your SSH client to use Vouch certificates:

```bash
vouch setup ssh
```

### SSH into the Demo Instance

The demo EC2 instance is pre-configured via user-data to trust the Vouch SSH CA, so it's ready for certificate-based SSH immediately after deploy:

```bash
$(terraform output -raw ssh_connect_command)
```

Any valid Vouch certificate can log in as `ec2-user`. No additional server configuration is needed.

You can still use SSM if you prefer:

```bash
$(terraform output -raw ssm_connect_command)
```

### Configuring Other Hosts (Ansible)

For hosts outside this demo, the included Ansible role configures `sshd` to trust the Vouch SSH CA with principal-based access control.

**1. Set up inventory:**

```bash
cp ansible/inventory/hosts.example ansible/inventory/hosts
```

Edit `ansible/inventory/hosts` and add your target hosts:

```ini
[servers]
host1.example.com
host2.example.com
```

**2. Configure authorized principals.** Edit the playbook at `ansible/playbooks/sshd-ca.yml` to control which certificate principals can log in as which local users:

```yaml
- name: Configure sshd to trust Vouch SSH CA
  hosts: all
  become: true
  roles:
    - role: vouch_sshd
      vars:
        vouch_authorized_principals:
          root:
            - admin
          deploy:
            - deploy
            - ci
```

With this configuration, only certificates carrying the `admin` principal can SSH as `root`, and only `deploy` or `ci` principals can SSH as `deploy`.

**3. Run the playbook:**

```bash
ansible-playbook -i ansible/inventory/hosts ansible/playbooks/sshd-ca.yml
```

The role fetches the Vouch CA public key, installs it on the host, creates an `sshd` config drop-in to trust it, and writes per-user authorized principals files. Re-running the playbook picks up any CA key rotations automatically.

## Cleanup

Destroy all provisioned infrastructure:

```bash
cd examples/complete
terraform destroy
```

## License

This project is licensed under the [MIT License](LICENSE).
