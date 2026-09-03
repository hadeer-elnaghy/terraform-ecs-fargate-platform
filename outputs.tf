output "alb_url" {
  description = "Access URL for the application"
  value       = "http://${module.alb.alb_dns_name}"
}
