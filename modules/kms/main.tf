# Generate a unique KMS key for Vault Auto-Unseal
resource "aws_kms_key" "vault" {
  description             = "KMS key for Vault auto-unseal"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # This policy is the "Security Guard" for the key itself
  policy = data.aws_iam_policy_document.kms_key_policy.json

  tags = {
    Name        = "${var.environment}-vault-kms"
    Environment = var.environment
  }
}

# Create a friendly alias for the key
resource "aws_kms_alias" "vault" {
  name          = "alias/vault-unseal-${var.environment}"
  target_key_id = aws_kms_key.vault.key_id
}

# The Key Policy Document
data "aws_iam_policy_document" "kms_key_policy" {
  # 1. Allow Root user full access (Standard AWS Requirement)
  statement {
    sid    = "Enable IAM User Permissions"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  # 2. Allow the ECS Task Role to use the key for encryption/decryption
  statement {
    sid    = "Allow Vault ECS Task to use the key"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.ecs_task_role_arn]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:DescribeKey"
    ]
    resources = ["*"]
  }
}

data "aws_caller_identity" "current" {}