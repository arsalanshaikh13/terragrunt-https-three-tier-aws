# # Get the certificate from AWS ACM
# data "aws_acm_certificate" "issued" {
#   domain   = var.certificate_domain_name
#   statuses = ["ISSUED"]
# }

#creating Cloudfront distribution :
resource "aws_cloudfront_distribution" "my_distribution" {
  enabled             = true
  aliases             =  [var.additional_domain_name]
  origin {
    domain_name = var.alb_domain_name
    origin_id   = var.alb_domain_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      # origin_protocol_policy = "http-only"
      # https://www.stormit.cloud/blog/cloudfront-distribution-for-amazon-ec2-alb/
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = var.alb_domain_name
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      # headers      = []
      headers      = ["host"]
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      # restriction_type = "whitelist"
      # locations        = ["IN", "US", "CA"]
      restriction_type = "none"

    }
  }
  tags = {
    Name = var.project_name
  }
  viewer_certificate {
    # acm_certificate_arn      = data.aws_acm_certificate.issued.arn
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}

# resource "aws_cloudfront_distribution" "my_distribution" {
#   enabled = true


#   origin {
#     domain_name = var.alb_domain_name
#     origin_id   = var.alb_domain_name

#     custom_origin_config {
#       http_port              = 80
#       https_port              = 443
#       origin_protocol_policy = "http-only"
#       origin_ssl_protocols = ["TLSv1.2"]
#     }
#   }
#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#     }
#   }

#   viewer_certificate {
#       cloudfront_default_certificate = true
#   }
#   default_cache_behavior {
#     allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
#     cached_methods         = ["GET", "HEAD", "OPTIONS"]
#     target_origin_id       = var.alb_domain_name
#     viewer_protocol_policy = "allow-all"
#     forwarded_values {
#       headers      = []
#       query_string = true
#       cookies {
#         forward = "all"
#       }
#     }
#   }

#   tags = {
#     Name = var.project_name
#   }
# }
