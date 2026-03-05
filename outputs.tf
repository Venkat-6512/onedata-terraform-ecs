# ─────────────────────────────────────────────────────────────────────────────
# Outputs — printed after terraform apply
# ─────────────────────────────────────────────────────────────────────────────

output "alb_dns_name" {
  description = "ALB DNS name — use this to curl the service"
  value       = aws_lb.main.dns_name
}

output "alb_url" {
  description = "Full URL to access the application"
  value       = "http://${aws_lb.main.dns_name}"
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.main.name
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs (where ECS runs)"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs (where ALB runs)"
  value       = aws_subnet.public[*].id
}

output "ssm_parameter_name" {
  description = "SSM parameter name for container image URI"
  value       = aws_ssm_parameter.container_image_uri.name
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for ECS tasks"
  value       = aws_cloudwatch_log_group.ecs.name
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alarm notifications"
  value       = aws_sns_topic.alarms.arn
}
