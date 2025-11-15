
# # creating aws_route53_zone using terraform
# resource "aws_route53_zone" "devsandbox" {
#   # name    = "devsandbox.space"
#   name    = var.certificate_domain_name
#   comment = "Hosted zone for devsandbox.space domain"

#   tags = {
#     # Name        = "devsandbox.space"
#     Name        = var.certificate_domain_name
#     Environment = "production"
#     ManagedBy   = "terraform"
#   }
# }

# # Output the name servers for updating domain registrar
# output "hosted_zone_name_servers" {
#   description = "Name servers to configure at domain registrar"
#   value       = aws_route53_zone.devsandbox.name_servers
# }

# # Output the hosted zone ID
# output "hosted_zone_id" {
#   description = "Route53 Hosted Zone ID"
#   value       = aws_route53_zone.devsandbox.zone_id
# }

# # Output the hosted zone ARN
# output "hosted_zone_arn" {
#   description = "Route53 Hosted Zone ARN"
#   value       = aws_route53_zone.devsandbox.arn
# }
# # Output the hosted zone ARN
# output "hosted_zone_name" {
#   description = "Route53 Hosted Zone ARN"
#   value       = aws_route53_zone.devsandbox.name
# }

data "aws_route53_zone" "public-zone" {
  name         = var.hosted_zone_name
  private_zone = false
}
resource "aws_route53_record" "cloudfront_record" {
  zone_id = data.aws_route53_zone.public-zone.zone_id
  # name    = "week3.${data.aws_route53_zone.public-zone.name}"
  name    = "${data.aws_route53_zone.public-zone.name}"
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
# trying to create an A record for aliases of domain name used in cloudfront 
resource "aws_route53_record" "cloudfront" {
  # for_each = aws_cloudfront_distribution.s3_distribution.aliases
  # for_each = toset(var.cloudfront_distro_aliases)
  for_each = toset(jsondecode(var.cloudfront_distro_aliases))
  zone_id  = data.aws_route53_zone.public-zone.zone_id
  name     = each.value
  type     = "A"

  alias {
    # name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    # zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}
