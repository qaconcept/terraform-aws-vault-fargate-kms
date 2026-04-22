output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The ID of the VPC"
}

output "vault_task_role_arn" {
  value       = module.ecs_vault.vault_task_role_arn
  description = "The ARN of the ECS Task Role used for KMS policy"
}

output "vault_sg_id" {
  value       = module.ecs_vault.vault_sg_id
  description = "The Security Group ID of the Vault tasks (used by EFS)"
}

output "vault_ui_url" {
  value       = "http://${module.ecs_vault.alb_dns_name}"
  description = "Access the Vault UI here"
}

output "kms_key_arn" {
  value       = module.kms.kms_key_arn
  description = "The ARN of the KMS key for auto-unseal"
}

output "efs_id" {
  value       = module.efs.efs_id
  description = "The ID of the EFS file system"
}