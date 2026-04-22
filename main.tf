# 1. Network Layer
module "vpc" {
  source      = "./modules/vpc"
  region      = var.region
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
}

# 2. Storage Layer - Move this UP so IDs are ready
module "efs" {
  source           = "./modules/efs"
  environment      = var.environment
  vpc_id           = module.vpc.vpc_id
  private_subnets  = module.vpc.private_subnets
  vault_task_sg_id = module.ecs_vault.vault_sg_id # SG comes from ECS
}

# 3. ECS Layer
module "ecs_vault" {
  source          = "./modules/ecs-vault"
  region          = var.region
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  private_subnets = module.vpc.private_subnets
  public_subnets  = module.vpc.public_subnets
  kms_key_arn     = module.kms.kms_key_arn
  efs_id          = module.efs.efs_id
  # FIX: You must pass the Access Point ID here
  efs_access_point_id = module.efs.efs_access_point_id 
}

# 4. Security Layer
module "kms" {
  source            = "./modules/kms"
  environment       = var.environment
  ecs_task_role_arn = module.ecs_vault.vault_task_role_arn
}