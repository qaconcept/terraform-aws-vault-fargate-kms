resource "aws_efs_file_system" "vault" {
  creation_token = "${var.environment}-vault-efs"
  encrypted      = true

  tags = {
    Name        = "${var.environment}-vault-efs"
    Environment = var.environment
  }
}

# Mount targets for each private subnet
resource "aws_efs_mount_target" "vault" {
  count           = length(var.private_subnets)
  file_system_id  = aws_efs_file_system.vault.id
  subnet_id       = var.private_subnets[count.index]
  security_groups = [aws_security_group.efs.id]
}

# Security Group for EFS (Allows NFS traffic from Vault tasks)
resource "aws_security_group" "efs" {
  name        = "${var.environment}-vault-efs-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.vault_task_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_efs_access_point" "vault" {
  file_system_id = aws_efs_file_system.vault.id

  posix_user {
    uid = 100
    gid = 1000
  }

  root_directory {
    path = "/vault"
    creation_info {
      owner_uid   = 100
      owner_gid   = 1000
      permissions = "755"
    }
  }
}