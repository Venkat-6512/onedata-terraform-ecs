# ─────────────────────────────────────────────────────────────────────────────
# CloudWatch Alarms + SNS Notifications
# Alarm 1: ECS task count drops to 0
# Alarm 2: ALB 5xx errors exceed 10 per minute
# ─────────────────────────────────────────────────────────────────────────────

# ── SNS Topic for alarm notifications ────────────────────────────────────────
resource "aws_sns_topic" "alarms" {
  name         = "${var.project_name}-alarms"
  display_name = "OneData ECS Alarms"

  tags = {
    Name = "${var.project_name}-alarms-topic"
  }
}

# Subscribe email to SNS topic
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint  = var.alarm_email
}

# ── Alarm 1: ECS Task Count = 0 ──────────────────────────────────────────────
# Fires when all ECS tasks are down — service is completely unavailable
resource "aws_cloudwatch_metric_alarm" "ecs_task_count_zero" {
  alarm_name          = "${var.project_name}-task-count-zero"
  alarm_description   = "CRITICAL: ECS service has 0 running tasks — service is down"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "RunningTaskCount"
  namespace           = "ECS/ContainerInsights"
  period              = 60
  statistic           = "Average"
  threshold           = 1
  treat_missing_data  = "breaching"  # no data = assume it's down

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.main.name
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name = "${var.project_name}-task-count-alarm"
  }
}

# ── Alarm 2: ALB 5xx Errors > 10 per minute ──────────────────────────────────
# Fires when the ALB is returning server errors at a high rate
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project_name}-alb-5xx-errors"
  alarm_description   = "ALB HTTP 5xx errors exceeding 10 per minute"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 10
  treat_missing_data  = "notBreaching"  # no data = assume it's fine

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  ok_actions    = [aws_sns_topic.alarms.arn]

  tags = {
    Name = "${var.project_name}-alb-5xx-alarm"
  }
}
