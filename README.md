# terraform-aws-vault-fargate-kms
Enterprise-grade, Highly Available HashiCorp Vault cluster on AWS ECS Fargate. Features KMS Auto-Unseal, Raft consensus on EFS, and serverless scalability. Fully automated with Terraform.

🚀 Deployment Workflow
To keep costs optimized, this environment is designed for rapid deployment and teardown.

1. Initialize Terraform

Bash
terraform init
2. Preview the Infrastructure

Bash
terraform plan -out=tfplan
3. Deploy (approx. 5-7 minutes)

Bash
terraform apply tfplan
4. Teardown (Important for Cost Management)
When finished with a demonstration or testing, ensure all resources are removed to stop AWS billing.

Bash
terraform destroy -auto-approve

## Deployment Notes (April 2026)
- **Bypass Capability Errors**: Added `SKIP_SETCAP = "true"` to environment variables to avoid Fargate permission issues.
- **Raft Storage**: Configured with EFS. Note: Raft requires an exclusive lock on the BoltDB file; only one task can run at a time (`desired_count = 1`).
- **Auto-Unseal**: Integrated with AWS KMS. The cluster will auto-unseal on boot once initialized.
- **Initialization**: Run `vault operator init` on first deploy to establish the Raft cluster and generate recovery keys.