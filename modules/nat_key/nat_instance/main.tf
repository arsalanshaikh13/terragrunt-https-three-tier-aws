
############################################
# VPC and Subnet Configuration
############################################

# # Create VPC using the official AWS VPC module
# module "vpc" {
#     source  = "terraform-aws-modules/vpc/aws"
#     version = "5.21.0"

#     name = "my-vpc"
#     cidr = "10.11.0.0/16"  # 65,536 IP addresses

#     # Define AZs and subnet ranges
#     azs             = ["us-east-2a", "us-east-2b"] # 2 Availability Zones
#     private_subnets = ["10.11.1.0/26", "10.11.2.0/26"]    # 62 IPs each
#     public_subnets  = ["10.11.101.0/24", "10.11.102.0/24"] # 254 IPs each

#     enable_nat_gateway = false # Using custom NAT instance instead of managed NAT gateway

#     tags = {
#         Terraform   = "true"
#         Environment = "dev"
#     }
# }

##########################################
# AMI Configuration
##########################################

# Fetch the latest ARM64 Amazon Linux 2023 AMI
data "aws_ami" "latest_amazon_linux" {
    most_recent = true

    filter {
        name   = "name"
        values = ["al2023-ami-2023.*-arm64"] # Using ARM for cost optimization
    }

    filter {
        name   = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["amazon"]
}

##########################################
# NAT Instance Configuration
##########################################

# Create the NAT instance in the public subnet
resource "aws_instance" "nat_ec2_instance" {
    # count = var.nat_instance_count
    ami           = data.aws_ami.latest_amazon_linux.id
    # instance_type = "t4g.micro"  # ARM-based instance for cost optimization
    # instance_type = "t4g.small"  # 750 hrs free / month till dec 31 2025
    instance_type = var.nat_instance_type  # 750 hrs free / month till dec 31 2025
    subnet_id     = var.pub_sub_1a_id
    associate_public_ip_address = true
    
    # iam_instance_profile = var.s3_ssm_instance_profile_name
    iam_instance_profile = var.s3_ssm_cw_instance_profile_name
    
    # Bootstrap script to configure NAT functionality
    user_data = filebase64("${path.module}/iptables.sh")

    source_dest_check      = false  # Required for NAT functionality
    vpc_security_group_ids = [aws_security_group.nat_ec2_sg.id]

    tags = {
        Name        = "self-managed-nat-ec2-instance"
        Terraform   = "true"
        Environment = "dev"
    }

    root_block_device {
        volume_type = var.nat_volume_type
        volume_size = var.nat_volume_size
    }

    lifecycle {
      ignore_changes = [ami]
      create_before_destroy = false
    }
}

# Security group for the NAT instance
resource "aws_security_group" "nat_ec2_sg" {
    name        = "self-managed-nat-ec2-sg"
    description = "Security group of Self-Managed NAT EC2 Instance"
    vpc_id      = var.vpc_id

    # Allow all TCP traffic from within the VPC
    ingress {
        from_port   = 0
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = [var.vpc_cidr_block]
        description = "Allow all TCP traffic from VPC CIDR"
    }

    # Allow all outbound traffic
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Allow all outbound traffic"
    }

    tags = {
        Name        = "self-managed-nat-ec2-instance-sg"
        Terraform   = "true"
        Environment = "dev"
    }
}


##########################################
# Route Table Configuration
##########################################

# # Add route for private subnet traffic through NAT instance
# resource "aws_route" "nat_ec2_route" {
#     route_table_id         = module.vpc.private_route_table_ids[0]
#     destination_cidr_block = "0.0.0.0/0"
#     network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
# }


# # Add route for private subnet traffic through NAT instance
resource "aws_route" "nat_ec2_route" {
    route_table_id         = var.pri_rt_a_id
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
}

resource "aws_route" "nat_ec2_route1" {
    route_table_id         = var.pri_rt_b_id
    destination_cidr_block = "0.0.0.0/0"
    network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
}






# # create private route table Pri-RT-A and add route through NAT-GW-A
# resource "aws_route_table" "pri-rt-a" {
#   vpc_id            = var.vpc_id

#   route {
#     cidr_block      = "0.0.0.0/0"
#     # nat_gateway_id  = aws_nat_gateway.nat-a.id
#     network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
#   }

#   tags   = {
#     Name = "Pri-rt-a"
#   }
# }

# # Web tier
# # associate private subnet pri-sub-3-a with private route table Pri-RT-A
# resource "aws_route_table_association" "pri-sub-3a-with-Pri-rt-a" {
#   subnet_id         = var.pri_sub_3a_id
#   route_table_id    = aws_route_table.pri-rt-a.id
# }

# # associate private subnet pri-sub-4b with private route table Pri-rt-b
# resource "aws_route_table_association" "pri-sub-4b-with-Pri-rt-b" {
#   subnet_id         = var.pri_sub_4b_id
#   route_table_id    = aws_route_table.pri-rt-a.id
# }

# # create private route table Pri-rt-b and add route through nat-b
# resource "aws_route_table" "pri-rt-b" {
#   vpc_id            = var.vpc_id

#   route {
#     cidr_block      = "0.0.0.0/0"
#     # nat_gateway_id  = aws_nat_gateway.nat-b.id
#     network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
#   }

#   tags   = {
#     Name = "pri-rt-b"
#   }
# }


# # internal app tier
# # associate private subnet pri-sub-5a with private route Pri-rt-b
# resource "aws_route_table_association" "pri-sub-5a-with-pri-rt-b" {
#   subnet_id         = var.pri_sub_5a_id
#   route_table_id    = aws_route_table.pri-rt-b.id
# }

# # associate private subnet pri-sub-6b with private route table Pri-rt-b
# resource "aws_route_table_association" "pri-sub-6b-with-pri-rt-b" {
#   subnet_id         = var.pri_sub_6b_id
#   route_table_id    = aws_route_table.pri-rt-b.id
# }