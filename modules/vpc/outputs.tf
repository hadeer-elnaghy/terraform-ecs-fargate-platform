output "vpc_id" {
  description = "VPC ID to attach security groups and services"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "Public subnet IDs used by the Application Load Balancer"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where ECS Fargate tasks will launch"
  value       = aws_subnet.private[*].id
}
