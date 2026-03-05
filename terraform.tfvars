# ─────────────────────────────────────────────────────────────────────────────
# OneData DevOps Assessment — Task 2
# Terraform variable values
# ─────────────────────────────────────────────────────────────────────────────

aws_region   = "us-east-1"
environment  = "staging"
project_name = "onedata"

# VPC
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones   = ["us-east-1a", "us-east-1b"]

# ECS
container_port        = 3000
task_cpu              = 256
task_memory           = 512
service_desired_count = 1

# Auto Scaling
autoscaling_min_capacity = 1
autoscaling_max_capacity = 4
autoscaling_cpu_target   = 60

# Alerts
alarm_email = "venkat@example.com"
