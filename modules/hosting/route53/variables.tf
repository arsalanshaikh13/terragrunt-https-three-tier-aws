variable "hosted_zone_name" {
  type        = string
  description = "hosted_zone_name variable"
    # default = "devsandbox.space"

}

variable "cloudfront_domain_name" {
  type        = string
  description = "cloudfront_domain_name variable"
}

variable "cloudfront_hosted_zone_id" {
  type        = string
  description = "cloudfront_hosted_zone_id variable"
}

variable "cloudfront_distro_aliases" {
  type        = string
  description = "cloudfront_distro_aliases variable"
}

