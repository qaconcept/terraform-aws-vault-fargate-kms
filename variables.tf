# terraform-aws-vault-fargate-kms/variables.tf
variable "region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type    = string
  default = "production"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "route53_zone_id" {
  description = "The ID of the Route 53 Hosted Zone"
  type        = string
}

variable "domain_name" {
  description = "The custom domain for Vault (e.g., vault.sreconcepts.com)"
  type        = string
}

variable "efs_file_system_arn" {
  description = "The ARN of the EFS file system for Vault storage"
  type        = string
}