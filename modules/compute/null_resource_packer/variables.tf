variable "db_name" {
  type        = string
  description = "db_name variable"
}

variable "db_password" {
  type        = string
  description = "db_password variable"
}

variable "db_port" {
  type        = string
  description = "db_port variable"
}

variable "db_secret_name" {
  type        = string
  description = "db_secret_name variable"
}

variable "db_sg_id" {
  type        = string
  description = "db_sg_id variable"
}

variable "db_username" {
  type        = string
  description = "db_username variable"
}

variable "endpoint_address" {
  type        = string
  description = "endpoint_address variable"
}

variable "internal_alb_dns_name" {
  type        = string
  description = "internal_alb_dns_name variable"
}

variable "panda_bucket_name" {
  type        = string
  description = "panda_bucket_name variable"
}

variable "pub_sub_1a_id" {
  type        = string
  description = "pub_sub_1a_id variable"
}

variable "region" {
  type        = string
  description = "region variable"
}

variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  description = "s3_ssm_cw_instance_profile_name variable"
}

variable "vpc_id" {
  type        = string
  description = "vpc_id variable"
}
variable "packer_folder" {
  type        = string
  description = "packer_folder variable"
}

# variable "instance_type" {
#   type        = string
#   description = "instance_type variable"
# }

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

variable "backend_ami_name" {
  type        = string
  description = "backend_ami_name variable"
}

variable "frontend_ami_name" {
  type        = string
  description = "frontend_ami_name variable"
}

variable "ssh_username" {
  type        = string
  description = "ssh_username variable"
}

variable "backend_ami_type" {
  type        = string
  description = "backend_ami_type variable"
}

variable "ssh_interface" {
  type        = string
  description = "ssh_interface variable"
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

variable "frontend_ami_type" {
  type        = string
  description = "frontend_ami_type variable"
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

