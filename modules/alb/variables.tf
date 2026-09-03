variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where the ALB and Target Group will be created"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB"
  type        = list(string)
}

variable "container_port" {
  description = "Port exposed by the application container"
  type        = number
  default     = 80
}
