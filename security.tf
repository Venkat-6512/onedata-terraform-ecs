# ─────────────────────────────────────────────────────────────────────────────
# Security Groups
# Rule: Internet → ALB ✅  |  Internet → ECS ❌  |  ALB → ECS ✅
# ─────────────────────────────────────────────────────────────────────────────

# ── ALB Security Group ────────────────────────────────────────────────────────
# Accepts HTTP/HTTPS from anywhere on the internet
resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "ALB security group - allows HTTP/HTTPS from internet"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound (to reach ECS tasks)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ── ECS Security Group ────────────────────────────────────────────────────────
# CRITICAL: Only accepts traffic from ALB security group
# No direct internet access to containers
resource "aws_security_group" "ecs" {
  name        = "${var.project_name}-ecs-sg"
  description = "ECS Fargate SG - only allows traffic from ALB"
  vpc_id      = aws_vpc.main.id

  # ONLY allow inbound from ALB security group on container port
  # This enforces: all traffic MUST go through ALB
  ingress {
    description     = "Container port from ALB only"
    from_port       = var.container_port
    to_port         = var.container_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Allow all outbound (for pulling images, calling AWS APIs)
  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-sg"
  }
}
