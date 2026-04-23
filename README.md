🚀 Automation-Vault: Quick Start Guide
A production-grade HashiCorp Vault deployment on AWS Fargate with KMS Auto-Unseal.

🧼 Clean Room Testing (Simulate New User)
If you are re-testing and want to ensure no conflicts with "Pending Deletion" resources:

Rotate Environment: Open terraform.tfvars and change environment (e.g., from "test" to "prod-v1").

Clear State: Run rm -rf .terraform terraform.tfstate* to wipe local memory.

Provision: Run terraform init and terraform apply.

🛠️ Phase 1: Infrastructure & Vault Setup
1. Provision AWS Resources
Bash
terraform init
terraform apply 
2. Initialize Vault
Check Terraform outputs for the ALB DNS name:

Bash
export VAULT_ADDR="https://vault.sreconcepts.com"
vault operator init
vault login <root_token>
3. Configure AppRole Identity
Bash
vault auth enable approle

vault policy write automation-vault-policy - <<EOF
path "secret/data/automation-vault/*" {
  capabilities = ["read"]
}
EOF

vault write auth/approle/role/automation-agent \
    token_policies="automation-vault-policy" \
    token_ttl=1h
🔐 Phase 2: Bridging Vault to AWS
1. Generate Agent Credentials
Bash
# Get the RoleID
vault read -field=role_id auth/approle/role/automation-agent/role-id

# Generate a one-time SecretID
vault write -f -field=secret_id auth/approle/role/automation-agent/secret-id
2. Seed AWS Secrets Manager
Log into AWS Console -> Secrets Manager.

Find the secret: ${environment}/automation-vault/secret-id.

Click Retrieve Secret Value -> Edit -> Paste your secret_id.

🐍 Phase 3: Testing the Agent
1. Local Python Test (Python 3.13)
Bash
export VAULT_ADDR="https://vault.sreconcepts.com"
export VAULT_ROLE_ID="<your_role_id>"
export VAULT_SECRET_ID="<your_secret_id>"

python3 vault_agent.py
Cleanup Notice: Run terraform destroy when finished. Note that KMS keys will enter "Pending Deletion" for 7 days; use the Suffix Strategy above to bypass this for future tests.