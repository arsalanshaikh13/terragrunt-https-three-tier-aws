variable "project_name" {
  type        = string
  description = "project_name variable"
}

variable "frontend_ami_id" {
  type        = string
  description = "frontend_ami_id variable"
}

# variable "instance_type" {
#   type        = string
#   description = "instance_type variable"
# }

variable "client_sg_id" {
  type        = string
  description = "client_sg_id variable"
}

variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  description = "s3_ssm_cw_instance_profile_name variable"
}

variable "backend_ami_id" {
  type        = string
  description = "backend_ami_id variable"
}

variable "server_sg_id" {
  type        = string
  description = "server_sg_id variable"
}

# variable "volume_type" {
#   type        = string
#   description = "volume_type variable"
# }

# variable "volume_size" {
#   type        = number
#   description = "volume_size variable"
# }

variable "environment" {
  type        = string
  description = "environment variable"
}

variable "max_size" {
  type        = number
  description = "max_size variable"
}

variable "min_size" {
  type        = number
  description = "min_size variable"
}

variable "desired_cap" {
  type        = number
  description = "desired_cap variable"
}

variable "asg_health_check_type" {
  type        = string
  description = "asg_health_check_type variable"
}

variable "pri_sub_3a_id" {
  type        = string
  description = "pri_sub_3a_id variable"
}

variable "pri_sub_4b_id" {
  type        = string
  description = "pri_sub_4b_id variable"
}

variable "tg_arn" {
  type        = string
  description = "tg_arn variable"
}


variable "pri_sub_5a_id" {
  type        = string
  description = "pri_sub_5a_id variable"
}

variable "pri_sub_6b_id" {
  type        = string
  description = "pri_sub_6b_id variable"
}

variable "internal_tg_arn" {
  type        = string
  description = "internal_tg_arn variable"
}


variable "frontend_instance_type" {
  type        = string
  description = "frontend_instance_type variable"
}

variable "frontend_volume_type" {
  type        = string
  description = "frontend_volume_type variable"
}

variable "frontend_volume_size" {
  type        = string
  description = "frontend_volume_size variable"
}

variable "backend_instance_type" {
  type        = string
  description = "backend_instance_type variable"
}

variable "backend_volume_type" {
  type        = string
  description = "backend_volume_type variable"
}

variable "backend_volume_size" {
  type        = string
  description = "backend_volume_size variable"
}

