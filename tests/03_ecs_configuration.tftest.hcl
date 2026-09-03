variables {
  environment = "test"
  aws_region  = "us-east-1"
}

run "verify_ecs_service_and_cluster" {
  command = plan

  # Ensure cluster name matches the environment prefix
  assert {
    condition     = module.ecs.cluster_name == "test-ecs-cluster"
    error_message = "ECS cluster name must adhere to the '<environment>-ecs-cluster' convention."
  }

  # Ensure service name matches the environment prefix
  assert {
    condition     = module.ecs.service_name == "test-service"
    error_message = "ECS service name must adhere to the '<environment>-service' convention."
  }
}
