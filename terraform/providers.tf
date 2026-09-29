# -----------------------------------------------------------------------------
# AWS Provider
# -----------------------------------------------------------------------------
# Credentials are expected via STS (aws configure, environment variables,
# IAM role on EC2/Lambda, or any standard AWS credential chain).
# credential_process from ~/.aws/config is supported.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # Profile to read from ~/.aws/config (which has your credential_process)
  profile = "terraform-process"

  default_tags {
    tags = {
      ManagedBy   = "terraform"
      Project     = var.project_name
      Environment = var.environment
    }
  }
}
