output "alb_dns_name" {
  description = "DNS name of ALB"
  value       = join("", aws_lb.webhublb.*.dns_name)
}

