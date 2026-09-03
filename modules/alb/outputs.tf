output "alb_dns_name" {
  description = "Public URL of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  value = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the Target Group to attach ECS Service"
  value       = aws_lb_target_group.app.arn
}

output "ecs_tasks_sg_id" {
  description = "Security Group ID to assign to ECS tasks"
  value       = aws_security_group.ecs_tasks.id
}

output "target_group_target_type" {
  description = "Target type for the ALB target group"
  value       = aws_lb_target_group.app.target_type
}

output "ecs_tasks_sg_name" {
  description = "Name of the ECS tasks security group"
  value       = aws_security_group.ecs_tasks.name
}
