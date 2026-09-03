# 1. ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.environment}-ecs-cluster"
  }
}

# 2. CloudWatch Log Group for Container Output
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.environment}-app"
  retention_in_days = 7

  tags = {
    Name = "${var.environment}-ecs-logs"
  }
}

# 3. SSM Parameter & Secrets Manager Secret
resource "aws_ssm_parameter" "app_env" {
  name  = "/${var.environment}/app/environment"
  type  = "String"
  value = var.environment
}

resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_secretsmanager_secret" "app_db_pass" {
  name                    = "${var.environment}-app-db-pass"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app_db_pass_val" {
  secret_id     = aws_secretsmanager_secret.app_db_pass.id
  secret_string = random_password.db_password.result
}

# 4. IAM Execution Role (Used by AWS Fargate agent to pull images and fetch secrets)
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_standard" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_secrets_access" {
  name = "${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_ssm_parameter.app_env.arn,
          aws_secretsmanager_secret.app_db_pass.arn
        ]
      }
    ]
  })
}

# 5. IAM Task Role (Used by the containerized application at runtime)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# 6. ECS Task Definition (Fargate)
resource "aws_ecs_task_definition" "app" {
  family                   = "${var.environment}-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn # Injected dedicated task role

  container_definitions = jsonencode([
    {
      name      = "${var.environment}-app"
      image     = var.container_image
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "app"
        }
      }
      secrets = [
        {
          name      = "APP_ENV"
          valueFrom = aws_ssm_parameter.app_env.arn
        },
        {
          name      = "DB_PASSWORD"
          valueFrom = aws_secretsmanager_secret.app_db_pass.arn
        }
      ]
    }
  ])
}

# 7. ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "${var.environment}-app"
    container_port   = var.container_port
  }

  # Prevent Terraform from overriding scaling decisions made by Application Auto Scaling
  lifecycle {
    ignore_changes = [desired_count]
  }

  depends_on = [aws_iam_role_policy_attachment.ecs_execution_standard]
}

# 8. ECS Auto-Scaling Target
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = 4
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 9. Target Tracking CPU Scaling Policy
resource "aws_appautoscaling_policy" "ecs_cpu" {
  name               = "${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300
    scale_out_cooldown = 60
  }
}
