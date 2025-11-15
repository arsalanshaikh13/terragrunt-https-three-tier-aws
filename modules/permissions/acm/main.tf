# create dns record in route53 for certificate
data "aws_route53_zone" "public-zone" {
  # name         = var.hosted_zone_name
  name         = var.certificate_domain_name
  private_zone = false
}


# AWS certificate Manager performing dns validation and creating certificate
resource "aws_acm_certificate" "cert" {
  domain_name       = var.certificate_domain_name
  subject_alternative_names = ["www.${var.certificate_domain_name}", "api.${var.certificate_domain_name}"]
  validation_method = "DNS"

  tags = {
    Environment = "test"
  }

  lifecycle {
    create_before_destroy = true
  }
}



resource "aws_route53_record" "cert_validation_record" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.public-zone.zone_id
}


resource "aws_acm_certificate_validation" "cert_validation" {
  timeouts {
    create = "5m"
  }
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_record : record.fqdn]
}




