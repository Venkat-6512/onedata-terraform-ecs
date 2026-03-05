# ─────────────────────────────────────────────────────────────────────────────
# SSM Parameter Store
# Container image URI stored here — read by ECS task definition
# CI/CD pipeline updates this after every build
# ─────────────────────────────────────────────────────────────────────────────

resource "aws_ssm_parameter" "container_image_uri" {
  name        = "/${var.project_name}/container-image-uri"
  description = "Container image URI for ECS task — updated by CI/CD pipeline"
  type        = "String"
  value       = "ghcr.io/venkat-6512/onedata-devops-api:latest"

  lifecycle {
    # CI/CD pipeline owns this value after initial creation
    ignore_changes = [value]
  }

  tags = {
    Name = "${var.project_name}-container-image-uri"
  }
}

# Read the value back for use in ECS task definition
data "aws_ssm_parameter" "container_image_uri" {
  name       = aws_ssm_parameter.container_image_uri.name
  depends_on = [aws_ssm_parameter.container_image_uri]
}
