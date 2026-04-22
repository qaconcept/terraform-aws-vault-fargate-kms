output "alb_dns_name" {
  value       = aws_lb.vault.dns_name
  description = "The DNS name of the load balancer"
}

output "vault_task_role_arn" {
  value       = aws_iam_role.vault_task_role.arn
  description = "The ARN of the ECS Task Role"
}

output "vault_sg_id" {
  value       = aws_security_group.vault_tasks.id
  description = "The Security Group ID of the Vault ECS tasks"
}