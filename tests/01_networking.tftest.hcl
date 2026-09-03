variables {
  environment = "test"
  aws_region  = "us-east-1"
}

run "verify_vpc_and_subnets" {
  command = plan

  # Verify exactly 2 public subnets exist across multi-AZ
  assert {
    condition     = length(module.vpc.public_subnet_ids) == 2
    error_message = "VPC must provision exactly 2 public subnets for the Multi-AZ Application Load Balancer."
  }

  # Verify exactly 2 private subnets exist for container isolation
  assert {
    condition     = length(module.vpc.private_subnet_ids) == 2
    error_message = "VPC must provision exactly 2 private subnets for ECS tasks."
  }

  # Ensure VPC ID is generated
  assert {
    condition     = module.vpc.vpc_cidr == "10.0.0.0/16"
    error_message = "VPC CIDR block should default to 10.0.0.0/16."
  }
}
