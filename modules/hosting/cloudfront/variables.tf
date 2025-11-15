
# variable "certificate_domain_name" {
#   type        = string
#   description = "certificate_domain_name variable"
# }
variable "additional_domain_name" {
  type        = string
  description = "additional_domain_name variable"
}

variable "alb_domain_name" {
  type        = string
  description = "alb_domain_name variable"
}

variable "project_name" {
  type        = string
  description = "project_name variable"
}

variable "acm_certificate_arn" {
  type        = string
  description = "acm_certificate_arn variable"
}

