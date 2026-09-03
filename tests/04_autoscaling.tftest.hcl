variables {
  environment = "test"
  aws_region  = "us-east-1"
}

run "verify_autoscaling_boundaries" {
  command = plan

  assert {
    condition     = module.ecs.service_name == "test-service"
    error_message = "Service must match the target auto-scaling target."
  }
}
