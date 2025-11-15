
# -------- Variables --------
variable "aws_region" {
  type        = string
  default     = "us-east-1"
  description = "AWS region where the AMI will be built."
}

variable "source_ami" {
  type        = string
  default     = ""
  description = "Base AMI id to use as the source image (set via -var or environment)."
}

variable "frontend_instance_type" {
  type = string
  # default = "t4g.micro"
  # default = "t4g.small"
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
  type    = string
  default = ""
}

variable "subnet_id" {
  type    = string
  default = ""
}
variable "s3_ssm_cw_instance_profile_name" {
  type        = string
  default     = ""
  description = "Instance profile for packer for ssm s3 and cw"
}
variable "bucket_name" {
  type        = string
  default     = ""
  description = "s3  bucket name"
}
variable "internal_alb_dns_name" {
  type        = string
  default     = ""
  description = "alb dns to alter "
}
variable "volume_type" {
  type        = string
  default     = ""
  description = "volume type of instance"
}
variable "volume_size" {
  type = number
  # default     = ""
  description = "volume storage size"
}
variable "environment" {
  type        = string
  default     = ""
  description = "environment - dev, prod, staging"
}
variable "frontend_ami_name" {
  type        = string
  default     = ""
  description = "frontend ami name"
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
# -------- Source (amazon-ebs builder) --------
source "amazon-ebs" "frontend" {
  region     = var.aws_region
  source_ami = var.source_ami
  # source_ami                  = data.amazon-ami.example.id
  instance_type               = var.frontend_instance_type
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  temporary_key_pair_name     = "packer-${local.timestamp}"
  ssh_username                = var.ssh_username
  # ssh_interface                 = "public_ip"
  ssh_timeout            = "10m"
  ssh_handshake_attempts = 30
  communicator           = "ssh"
  ssh_pty                = true
  # ssh_interface        = "session_manager"
  ssh_interface        = var.ssh_interface
  iam_instance_profile = var.s3_ssm_cw_instance_profile_name


  ami_name        = "${var.frontend_ami_name}-${local.timestamp}"
  ami_description = "Frontend AMI with Nginx and Git and react"
  tags = {
    Name        = var.frontend_ami_name
    Environment = var.environment
    Component   = "frontend"
  }

  launch_block_device_mappings {
    device_name           = "/dev/xvda"
    encrypted             = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size
    delete_on_termination = true
  }


}

# -------- Build (ties source -> provisioners -> post-processors) --------
build {
  sources = ["source.amazon-ebs.frontend"]

  
  provisioner "file" {
    source      = "client.sh"      # local file (in same dir as packer/terraform)
    destination = "/tmp/client.sh" # remote path inside EC2
  }

  provisioner "shell" {
    environment_vars = [
      "bucket_name=${var.bucket_name}",
      "internal_alb_dns_name=${var.internal_alb_dns_name}",
      "ssh_username=${var.ssh_username}",
    ]
    inline = [
      # dos2unix client.sh to convert CRLF to LF for linux
      # "set -euxo pipefail",
      "echo $internal_alb_dns_name  $bucket_name  ",
      "echo Running web-tier setup...",
      "sudo chmod +x /tmp/client.sh",
      "sudo -E bash /tmp/client.sh "
    ]
  }
  post-processor "manifest" {
    output = "manifest.json"
  }
}
