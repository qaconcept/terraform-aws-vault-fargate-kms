variable "environment" {
  type        = string
}

variable "vpc_id" {
  type        = string
}

variable "private_subnets" {
  type        = list(string)
}

variable "public_subnets" {
  type        = list(string)
}

variable "kms_key_arn" {
  type        = string
}

variable "region" {
  type        = string
  default     = "us-east-1"
}

variable "efs_id" {
  type        = string
  description = "The ID of the EFS file system for persistent Raft storage"
}

variable "efs_access_point_id" {
  type        = string
  description = "The ID of the EFS Access Point for Vault storage"
}

variable "efs_file_system_arn" {
  type        = string
  description = "Target EFS ARN for IAM policy restriction"
}

variable "certificate_arn" {
  type        = string
  description = "The ARN of the ACM certificate for the ALB"
}