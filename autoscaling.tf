# ─────────────────────────────────────────────────────────────────────────────
# ECS Auto Scaling
# Scales between 1 and 4 tasks based on CPU utilization > 60%
# ─────────────────────────────────────────────────────────────────────────────

# ── Scalable Target ───────────────────────────────────────────────────────────
resource "aws_appautoscaling_target" "ecs" {
  max_capacity       = var.autoscaling_max_capacity  # 4
  min_capacity       = var.autoscaling_min_capacity  # 1
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# ── CPU Scaling Policy ────────────────────────────────────────────────────────
# Scale out when CPU > 60%, scale in when CPU drops below
resource "aws_appautoscaling_policy" "cpu" {
  name               = "${var.project_name}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = var.autoscaling_cpu_target  # 60%
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

# ── Memory Scaling Policy (bonus) ─────────────────────────────────────────────
resource "aws_appautoscaling_policy" "memory" {
  name               = "${var.project_name}-memory-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs.service_namespace

  target_tracking_scaling_policy_configuration {
    target_value       = 80
    scale_in_cooldown  = 60
    scale_out_cooldown = 60

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}
