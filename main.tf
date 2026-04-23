# 1. Network Layer
module "vpc" {
  source      = "./modules/vpc"
  region      = var.region
  environment = var.environment
}

# 2. Security Layer (KMS)
module "kms" {
  source            = "./modules/kms"
  environment       = var.environment
  ecs_task_role_arn = module.ecs_vault.vault_task_role_arn
}

# 3. Storage Layer (EFS)
module "efs" {
  source           = "./modules/efs"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  vault_task_sg_id = module.ecs_vault.vault_sg_id
}

# 4. Identity & Secret Storage (New for Secure Injection)
resource "aws_secretsmanager_secret" "vault_secret_id" {
  name                    = "${var.environment}/automation-vault/secret-id"
  description             = "SecretID for Vault AppRole authentication"
  recovery_window_in_days = 0 # Set to 0 for easier testing/re-deployment tomorrow
}

resource "aws_ecr_repository" "agent" {
  name                 = "automation-vault-agent"
  image_tag_mutability = "MUTABLE"
  force_delete         = true
}

# 5. ECS Layer (Vault + Agent)
module "ecs_vault" {
  source              = "./modules/ecs-vault"
  region              = var.region
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnets     = module.vpc.private_subnets
  public_subnets      = module.vpc.public_subnets
  kms_key_arn         = module.kms.kms_key_arn
  efs_id              = module.efs.efs_id
  efs_access_point_id = module.efs.efs_access_point_id 
  
  # New Production-Grade Variables 
  efs_file_system_arn = var.efs_file_system_arn
  certificate_arn     = aws_acm_certificate.vault.arn

  # Secret Injection ARNs
  vault_secret_id_arn = aws_secretsmanager_secret.vault_secret_id.arn
  agent_ecr_url       = aws_ecr_repository.agent.repository_url
}