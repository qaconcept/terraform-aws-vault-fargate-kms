variable "environment" {}
variable "vpc_id" {}
variable "private_subnets" { type = list(string) }
variable "vault_task_sg_id" { description = "The SG ID of the Vault ECS Task" }