# ─────────────────────────────────────────────────────────────────────────────
# Application Load Balancer
# Internet-facing, placed in public subnets
# ECS tasks are in private subnets — only reachable via ALB
# ─────────────────────────────────────────────────────────────────────────────

# ── Application Load Balancer ─────────────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false          # internet-facing
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]

  # ALB lives in PUBLIC subnets
  subnets = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ── Target Group ──────────────────────────────────────────────────────────────
# Points to ECS Fargate tasks on container port
resource "aws_lb_target_group" "ecs" {
  name        = "${var.project_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"  # required for Fargate (not instance)

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# ── HTTP Listener ─────────────────────────────────────────────────────────────
# Listens on port 80, forwards to ECS target group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs.arn
  }
}
