# Output the certificate ARN
output "acm_certificate_arn" {
  description = "ACM Certificate ARN"
  value       = aws_acm_certificate.cert.arn
}

# Output the domain name
output "acm_certificate_domain_name" {
  description = "ACM Certificate Domain Name"
  value       = aws_acm_certificate.cert.domain_name
}

# Output the certificate status
output "acm_certificate_status" {
  description = "ACM Certificate Status"
  value       = aws_acm_certificate.cert.status
}