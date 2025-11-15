# packer.pkr.hcl
# Backend AMI: PHP + Apache + MySQL client

# -----------------------
# Variables
# -----------------------
variable "aws_region" {
  type = string
  # default     = "us-east-1"
  description = "AWS region to build the AMI in."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI to use as the source image (set via -var or a var-file)."
}

variable "backend_instance_type" {
  type = string
  # default     = "t4g.micro"
  # https://aws.amazon.com/ec2/instance-types/t4/
  # default     = "t4g.small"
  description = "EC2 instance type to use for the temporary build instance."
}

variable "ssh_username" {
  type = string
  # default     = "ec2-user"
  description = "SSH user for the temporary build instance."
}
variable "ssh_interface" {
  type = string
  # default     = "session_manager"
  description = "SSH interface for the temporary build instance."
}

variable "vpc_id" {
  type        = string
  default     = ""
  description = "VPC id where the build instance will be launched."
}

variable "subnet_id" {
  type        = string
  default     = ""
  description = "Subnet id where the build instance will be launched."
}

variable "security_group_id" {
  type        = string
  default     = ""
  description = "Security group id attached to the build instance (single SG)."
}

variable "rds_sg_id" {
  type        = string
  default     = ""
  description = "(Unused in template) RDS security group id — kept for consistency if you want to reference it elsewhere."
}

variable "db_host" {
  type        = string
  default     = ""
  description = "Database host endpoint used by mysql client to run the schema/import step."
}

variable "db_port" {
  type = string
  # default     = "3306"
  description = "Database port (string to match original)."
}
variable "db_name" {
  type        = string
  default     = ""
  description = "Database Name"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "DB user that has privileges to run the SQL in database_setup.sql."
}

variable "db_password" {
  type        = string
  default     = ""
  description = "DB password. Avoid committing secrets to source; use -var or a var-file."
  sensitive   = true
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
variable "db_secret_name" {
  type        = string
  default     = ""
  description = "secret to access from aws secret manager"
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "volume_type" {
  type        = string
  default     = ""
  description = "volume type of instance"
}
variable "volume_size" {
  type        = number
  description = "volume storage size"
}
variable "environment" {
  type        = string
  default     = ""
  description = "environment - dev, prod, staging"
}
variable "backend_ami_name" {
  type        = string
  default     = ""
  description = "backend ami name"
}


locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

# i am already searching for latest amazon ami in build_ami.sh
# data "amazon-ami" "example" {
#   filters = {
#     virtualization-type = "hvm"
#     name                = "al2023-ami-2023.*-arm64"
#     root-device-type    = "ebs"
#   }
#   owners      = ["amazon"]
#   most_recent = true
#   region      = "us-east-1"
# }
# -----------------------
# Source (amazon-ebs builder)
# -----------------------
source "amazon-ebs" "backend" {
  region     = var.aws_region
  source_ami = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type               = var.backend_instance_type
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  security_group_id           = var.security_group_id
  associate_public_ip_address = true
  ssh_username                = var.ssh_username
  temporary_key_pair_name     = "packer-${local.timestamp}"
  ssh_timeout                 = "10m"
  ssh_handshake_attempts      = 30
  communicator                = "ssh"
  ssh_pty                     = true
  # ssh_interface               = "public_ip"
  # ssh_interface = "session_manager"
  ssh_interface = var.ssh_interface

  iam_instance_profile = var.s3_ssm_cw_instance_profile_name


  ami_name        = "${var.backend_ami_name}-${local.timestamp}"
  ami_description = "Backend AMI with NodeJS, MySQL client, and CloudWatch agent"

  tags = {
    Component   = "backend"
    Environment = var.environment
    Name        = var.backend_ami_name
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }
}

# -----------------------
# Build (connects source -> provisioners -> post-processors)
# -----------------------
build {
  sources = ["source.amazon-ebs.backend"]

  provisioner "file" {
    source      = "server.sh"      # local file (in same dir as packer/terraform)
    destination = "/tmp/server.sh" # remote path inside EC2
  }

  provisioner "shell" {
    environment_vars = [
      "db_host=${var.db_host}",
      "db_username=${var.db_user}",
      "db_password=${var.db_password}",
      "db_name=${var.db_name}",
      "db_secret_name=${var.db_secret_name}",
      "bucket_name=${var.bucket_name}",
      "aws_region=${var.aws_region}",
      "ssh_username=${var.ssh_username}"
    ]
  
    inline = [
      "echo 'Running app-tier setup...'",
      "echo $db_name  $db_secret_name  ",
      "echo Bucket: $bucket_name",
      #### dos2unix server.sh to convert CRLF to LF to run on server linux instance
      "sudo chmod +x /tmp/server.sh",
      "sudo -E bash /tmp/server.sh "
    ]
  }
  
  post-processor "manifest" {
    output = "manifest.json"
  }
}
