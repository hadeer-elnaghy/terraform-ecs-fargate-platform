variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ECS service lives"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where Fargate tasks will launch"
  type        = list(string)
}

variable "ecs_tasks_sg_id" {
  description = "Security group ID allowing inbound from the ALB"
  type        = string
}

variable "target_group_arn" {
  description = "Target group ARN for registering container IP targets"
  type        = string
}

variable "container_port" {
  description = "Port the container application listens on"
  type        = number
  default     = 80
}

variable "container_image" {
  description = "Docker image to run (using public nginx for testing)"
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}
