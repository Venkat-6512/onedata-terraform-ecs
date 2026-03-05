terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # S3 backend — stores terraform.tfstate remotely
  # Allows Plan and Apply jobs to share state in GitHub Actions
  # ⚠️  UPDATE bucket name with your actual AWS Account ID before pushing
  # Example: onedata-terraform-state-123456789012
  backend "s3" {
    bucket = "onedata-terraform-state"
    key    = "ecs/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  # Credentials injected automatically via GitHub Actions OIDC
  # No hardcoded keys anywhere
  default_tags {
    tags = {
      Project     = "OneData-Assessment"
      Task        = "Task2-ECS-Fargate"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
