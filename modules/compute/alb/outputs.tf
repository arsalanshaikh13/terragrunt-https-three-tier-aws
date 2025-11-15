output "tg_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}
output "internal_tg_arn" {
  value = aws_lb_target_group.internal_alb_target_group.arn
}

output "alb_dns_name" {
  value = aws_lb.application_load_balancer.dns_name
}
output "internal_alb_dns_name" {
  value = aws_lb.internal_application_load_balancer.dns_name
}