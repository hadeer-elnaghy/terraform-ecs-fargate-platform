variables {
  environment = "test"
  aws_region  = "us-east-1"
}

run "verify_alb_and_target_group" {
  command = plan

  # Fargate REQUIRES target_type to be "ip" (not "instance")
  assert {
    condition     = module.alb.target_group_target_type == "ip"
    error_message = "Target group target_type must be set to 'ip' for Fargate integration."
  }

  # Verify the security group name follows the naming standard
  assert {
    condition     = module.alb.ecs_tasks_sg_name == "test-ecs-tasks-sg"
    error_message = "ECS tasks security group name must match '<environment>-ecs-tasks-sg'."
  }
}
