# ─────────────────────────────────────────────────────────────────────────────
# ECS Fargate — Cluster, Task Definition, Service
# Service runs in PRIVATE subnets with NO public IP
# Image URI is read from SSM Parameter Store
# ─────────────────────────────────────────────────────────────────────────────

# ── ECS Cluster ───────────────────────────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  # Enable Container Insights for detailed monitoring
  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

# ── CloudWatch Log Group ──────────────────────────────────────────────────────
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.project_name}-api"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-ecs-logs"
  }
}

# ── IAM Role for ECS Task Execution ──────────────────────────────────────────
# Allows ECS to pull images and write logs
resource "aws_iam_role" "ecs_task_execution" {
  name = "${var.project_name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-execution-role"
  }
}

# Attach AWS managed policy for ECS task execution
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ── IAM Role for ECS Task ─────────────────────────────────────────────────────
# The role the application itself uses at runtime
resource "aws_iam_role" "ecs_task" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ecs-task-role"
  }
}

# ── Fargate Task Definition ───────────────────────────────────────────────────
# Image URI is read from SSM — never hardcoded
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project_name}-api"
  network_mode             = "awsvpc"     # required for Fargate
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name  = "${var.project_name}-api"
      # Image URI read from SSM Parameter Store at deploy time
      image = data.aws_ssm_parameter.container_image_uri.value

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        { name = "NODE_ENV", value = "production" },
        { name = "PORT", value = tostring(var.container_port) }
      ]

      # Health check — Kubernetes-style inside the container
      healthCheck = {
        command     = ["CMD-SHELL", "wget -qO- http://localhost:${var.container_port}/health || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 15
      }

      # Send logs to CloudWatch
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Resource limits
      cpu    = var.task_cpu
      memory = var.task_memory

      essential = true
    }
  ])

  tags = {
    Name = "${var.project_name}-task-definition"
  }
}

# ── ECS Fargate Service ───────────────────────────────────────────────────────
# Runs in PRIVATE subnets — no public IP
# Only reachable via ALB
resource "aws_ecs_service" "main" {
  name            = "${var.project_name}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id   # private subnets only
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = false                       # NO public IP — enforces ALB-only access
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs.arn
    container_name   = "${var.project_name}-api"
    container_port   = var.container_port
  }

  # Rolling deployment — zero downtime
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  # Wait for ALB and task definition to be ready
  depends_on = [
    aws_lb_listener.http,
    aws_iam_role_policy_attachment.ecs_task_execution
  ]

  tags = {
    Name = "${var.project_name}-ecs-service"
  }

  lifecycle {
    ignore_changes = [desired_count]  # auto-scaling manages this
  }
}
