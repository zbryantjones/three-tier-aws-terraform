output "alb_dns_name" {
  description = "The URL to visit your app"
  value       = aws_lb.main.dns_name
}

output "rds_endpoint" {
  description = "Database connection endpoint"
  value       = aws_db_instance.main.endpoint
}