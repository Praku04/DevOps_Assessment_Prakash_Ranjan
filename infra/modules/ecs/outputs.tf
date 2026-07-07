output "alb_security_group_id" {
  value = aws_security_group.insurance_alb.id
}

output "ecs_security_group_id" {
  value = aws_security_group.insurance_security_group.id
}

output "alb_dns_name" {
  value = aws_lb.insurance_alb.dns_name
}
