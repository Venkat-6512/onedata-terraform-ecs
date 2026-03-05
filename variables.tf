variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "onedata"
}

# ── VPC ──────────────────────────────────────────────────────────────────────
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets (one per AZ)"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# ── ECS ──────────────────────────────────────────────────────────────────────
variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 3000
}

variable "task_cpu" {
  description = "Fargate task CPU units (256 = 0.25 vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "service_desired_count" {
  description = "Desired number of ECS tasks"
  type        = number
  default     = 1
}

# ── Auto Scaling ─────────────────────────────────────────────────────────────
variable "autoscaling_min_capacity" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "autoscaling_max_capacity" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 4
}

variable "autoscaling_cpu_target" {
  description = "Target CPU utilization percentage for auto-scaling"
  type        = number
  default     = 60
}

# ── CloudWatch ───────────────────────────────────────────────────────────────
variable "alarm_email" {
  description = "Email address for CloudWatch alarm notifications"
  type        = string
  default     = "venkat@example.com"
}
