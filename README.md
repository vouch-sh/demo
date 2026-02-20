# Vouch Demo

This tutorial walks you through using [Vouch](https://github.com/vouch-sh) to authenticate to AWS services with OIDC-based workload identity. You'll deploy demo infrastructure with Terraform, then use Vouch credentials to push code, install packages, push container images, connect to servers, and access Kubernetes clusters — all without long-lived AWS credentials.

## What You'll Need

- **Terraform** >= 1.10
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
# eks_enabled        = true   # ~$73/mo control plane — uncomment if needed
```

Deploy:

```bash
terraform init
terraform apply
```

**Cost:** With all services enabled except EKS, this costs ~$4/mo (a single t2.nano). Adding EKS brings it to ~$77/mo due to the control plane charge. All demo service modules default to disabled, so you only pay for what you turn on.

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
cd vouch-demo-repo
echo "hello from vouch" > test.txt
git add .
git commit -m "test push"
git push
```

## Step 5: Install Packages (CodeArtifact)

*Requires `codeartifact_enabled = true`.*

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

npm fetches the package from your CodeArtifact repository, authenticating with Vouch credentials.

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

## Step 8: Access Kubernetes (EKS)

*Requires `eks_enabled = true` and kubectl installed.*

> **Cost warning:** EKS Auto Mode has a ~$73/mo control plane charge. Destroy when not in use.

Update your kubeconfig:

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

## Step 9: SSH with Certificates

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
