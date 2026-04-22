output "kms_key_arn" {
  value       = aws_kms_key.vault.arn
  description = "The ARN of the KMS key"
}

output "kms_key_id" {
  value       = aws_kms_key.vault.key_id
  description = "The ID of the KMS key"
}