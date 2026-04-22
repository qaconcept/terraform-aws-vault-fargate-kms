variable "environment" {
  type        = string
  description = "Project environment"
}

variable "ecs_task_role_arn" {
  type        = string
  description = "The ARN of the IAM role used by the Vault ECS task"
}