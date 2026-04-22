# 1. The Task Execution Role (Allows ECS to pull images and push logs)
resource "aws_iam_role" "vault_execution_role" {
  name = "${var.environment}-vault-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "execution_role_policy" {
  role       = aws_iam_role.vault_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# 2. The Task Role (Used by the Vault application to talk to KMS and EFS)
resource "aws_iam_role" "vault_task_role" {
  name = "${var.environment}-vault-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

# 3. KMS Access Policy for Task Role (Required for Auto-Unseal)
resource "aws_iam_role_policy" "vault_kms_access" {
  name = "${var.environment}-vault-kms-access"
  role = aws_iam_role.vault_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Effect   = "Allow"
        Resource = [var.kms_key_arn]
      }
    ]
  })
}

# 4. ECS Cluster and Logging
resource "aws_ecs_cluster" "vault" {
  name = "${var.environment}-vault-cluster"
}

resource "aws_cloudwatch_log_group" "vault" {
  name              = "/ecs/${var.environment}-vault"
  retention_in_days = 7
}

# 5. Security Groups
resource "aws_security_group" "alb" {
  name        = "${var.environment}-vault-alb-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vault_tasks" {
  name        = "${var.environment}-vault-task-sg"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8200
    to_port         = 8200
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 6. Load Balancer Configuration
resource "aws_lb" "vault" {
  name               = "${var.environment}-vault-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnets
}

resource "aws_lb_target_group" "vault" {
  name        = "${var.environment}-vault-tg"
  port        = 8200
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path    = "/v1/sys/health"
    matcher = "200,429"
  }
}

resource "aws_lb_listener" "vault" {
  load_balancer_arn = aws_lb.vault.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vault.arn
  }
}

# 7. ECS Task Definition with EFS Persistent Storage
resource "aws_ecs_task_definition" "vault" {
  family                   = "vault"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.vault_execution_role.arn
  task_role_arn            = aws_iam_role.vault_task_role.arn

  # Volume definition connecting to EFS module via Access Point
  volume {
    name = "vault-storage"
    efs_volume_configuration {
      file_system_id     = var.efs_id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = var.efs_access_point_id
        iam             = "ENABLED"
      }
    }
  }

  container_definitions = jsonencode([{
    name    = "vault"
    image   = "hashicorp/vault:latest"
    command = ["server"] # Forces Vault to start in server mode
    user    = "100"      # Matches UID for EFS Access Point (vault user)

    portMappings = [
      {
        containerPort = 8200
        hostPort      = 8200
      },
      {
        containerPort = 8201
        hostPort      = 8201
      }
    ]
    
    mountPoints = [{
      sourceVolume  = "vault-storage"
      containerPath = "/vault/data"
      readOnly      = false
    }]

    environment = [
      { name = "VAULT_ADDR", value = "http://127.0.0.1:8200" },
      { name = "SKIP_CHOWN", value = "true" },
      { name = "SKIP_SETCAP", value = "true" },
      { name = "VAULT_LOCAL_CONFIG", value = jsonencode({
        storage = {
          raft = {
            path    = "/vault/data"
            node_id = "node1"
          }
        }
        cluster_addr  = "http://127.0.0.1:8201"
        api_addr      = "http://127.0.0.1:8200"
        disable_mlock = true # Mandatory for AWS Fargate compatibility
        log_level     = "trace" # Verbose logs to debug initialization
        
        seal = {
          awskms = {
            region     = var.region
            kms_key_id = var.kms_key_arn
          }
        }
        listener = {
          tcp = {
            address         = "0.0.0.0:8200"
            cluster_address = "0.0.0.0:8201"
            tls_disable     = "true"
          }
        }
        ui = true
      }) }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.vault.name
        "awslogs-region"        = var.region
        "awslogs-stream-prefix" = "vault"
      }
    }
  }])
}

# 8. ECS Service
resource "aws_ecs_service" "vault" {
  name            = "${var.environment}-vault-service"
  cluster         = aws_ecs_cluster.vault.id
  task_definition = aws_ecs_task_definition.vault.arn
  launch_type     = "FARGATE"
  desired_count   = 0

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.vault_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.vault.arn
    container_name   = "vault"
    container_port   = 8200
  }
}

# 9. IAM Policy for EFS Access (Required when authorization_config is ENABLED)
resource "aws_iam_role_policy" "vault_efs_access" {
  name = "${var.environment}-vault-efs-access"
  role = aws_iam_role.vault_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticfilesystem:ClientMount",
          "elasticfilesystem:ClientWrite",
          "elasticfilesystem:ClientRootAccess"
        ]
        Resource = "*" 
      }
    ]
  })
}