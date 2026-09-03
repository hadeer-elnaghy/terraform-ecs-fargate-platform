terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Production S3 Remote Backend with Native State Locking
  backend "s3" {
    bucket       = "my-ecs-tfstate-540087633584-2026"
    key          = "ecs-platform/dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = var.aws_region
}
