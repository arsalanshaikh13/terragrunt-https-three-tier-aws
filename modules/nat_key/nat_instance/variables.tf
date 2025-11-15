# variable pri_sub_3a_id {}
# variable pri_sub_4b_id {}
# variable pri_sub_5a_id {}
# variable pri_sub_6b_id {}
# variable "nat_instance_count" {
#   type        = number
#   description = "nat_instance_count variable"
# }
variable "nat_instance_type" {
  type        = string
  description = "nat_instance_type variable"
}

variable "pub_sub_1a_id" {
  type        = string
  description = "pub_sub_1a_id variable"
}

variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  description = "s3_ssm_cw_instance_profile_name variable"
}

variable "nat_volume_type" {
  type        = string
  description = "nat_volume_type variable"
}
variable "nat_volume_size" {
  type        = number
  description = "nat_volume_size variable"
  default = 8
}

variable "vpc_id" {
  type        = string
  description = "vpc_id variable"
}

variable "vpc_cidr_block" {
  type        = string
  description = "vpc_cidr_block variable"
}

variable "pri_rt_a_id" {
  type        = string
  description = "pri_rt_a_id variable"
}

variable "pri_rt_b_id" {
  type        = string
  description = "pri_rt_b_id variable"
}

