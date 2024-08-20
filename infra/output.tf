output "load_balancer_dns" {
  value       = aws_lb.app_nlb.dns_name
  description = "app load balancer DNS endpoint"
}