# create vpc
resource "aws_vpc" "vpc" {
  cidr_block              = var.vpc_cidr
  instance_tenancy        = "default"
  enable_dns_hostnames    = true
  enable_dns_support =  true

  tags      = {
    Name    = "${var.project_name}-vpc"
  }
}

# create internet gateway and attach it to vpc
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id    = aws_vpc.vpc.id

  tags      = {
    Name    = "${var.project_name}-igw"
  }
}

# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}

# create public subnet pub_sub_1a
resource "aws_subnet" "pub_sub_1a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_sub_1a_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "pub_sub_1a"
  }
}

# create public subnet pub_sub_2b
resource "aws_subnet" "pub_sub_2b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.pub_sub_2b_cidr
  availability_zone       = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch = true

  tags      = {
    Name    = "pub_sub_2b"
  }
}



# create route table and add public route
resource "aws_route_table" "public_route_table" {
  vpc_id       = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags       = {
    Name     = "Public-rt"
  }
}

# associate public subnet pub-sub-1a to public route table
resource "aws_route_table_association" "pub-sub-1a_route_table_association" {
  subnet_id           = aws_subnet.pub_sub_1a.id
  route_table_id      = aws_route_table.public_route_table.id
}

# associate public subnet az2 to "public route table"
resource "aws_route_table_association" "pub-sub-2-b_route_table_association" {
  subnet_id           = aws_subnet.pub_sub_2b.id
  route_table_id      = aws_route_table.public_route_table.id
}

# Web Layer
# create private app subnet pri-sub-3a
resource "aws_subnet" "pri_sub_3a" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_3a_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-3a"
  }
}

# create private app pri-sub-4b
resource "aws_subnet" "pri_sub_4b" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_4b_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-4b"
  }
}

# Internal Load balancer and App layer
# create private data subnet pri-sub-5a
resource "aws_subnet" "pri_sub_5a" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_5a_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-5a"
  }
}

# create private data subnet pri-sub-6-b
resource "aws_subnet" "pri_sub_6b" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_6b_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-6b"
  }
}
# Database Layer
# create private data subnet pri-sub-5a
resource "aws_subnet" "pri_sub_7a" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_7a_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[0]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-7a"
  }
}

# create private data subnet pri-sub-6-b
resource "aws_subnet" "pri_sub_8b" {
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = var.pri_sub_8b_cidr
  availability_zone        = data.aws_availability_zones.available_zones.names[1]
  map_public_ip_on_launch  = false

  tags      = {
    Name    = "pri-sub-8b"
  }
}


# Creating route table for vpc endpoint for vpc flow logs
# create private route table Pri-RT-A and add route through NAT-GW-A
resource "aws_route_table" "pri-rt-a" {
  vpc_id            = aws_vpc.vpc.id

  # route {
  #   cidr_block      = "0.0.0.0/0"
  #   # nat_gateway_id  = aws_nat_gateway.nat-a.id
  #   network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
  # }

  tags   = {
    Name = "Pri-rt-a"
  }
}

# Web tier
# associate private subnet pri-sub-3-a with private route table Pri-RT-A
resource "aws_route_table_association" "pri-sub-3a-with-Pri-rt-a" {
  subnet_id         = aws_subnet.pri_sub_3a.id
  route_table_id    = aws_route_table.pri-rt-a.id
}

# associate private subnet pri-sub-4b with private route table Pri-rt-b
resource "aws_route_table_association" "pri-sub-4b-with-Pri-rt-b" {
  subnet_id         = aws_subnet.pri_sub_4b.id
  route_table_id    = aws_route_table.pri-rt-a.id
}

# create private route table Pri-rt-b and add route through nat-b
resource "aws_route_table" "pri-rt-b" {
  vpc_id            = aws_vpc.vpc.id

  # route {
  #   cidr_block      = "0.0.0.0/0"
  #   # nat_gateway_id  = aws_nat_gateway.nat-b.id
  #   network_interface_id   = aws_instance.nat_ec2_instance.primary_network_interface_id
  # }

  tags   = {
    Name = "pri-rt-b"
  }
}


# internal app tier
# associate private subnet pri-sub-5a with private route Pri-rt-b
resource "aws_route_table_association" "pri-sub-5a-with-pri-rt-b" {
  subnet_id         = aws_subnet.pri_sub_5a.id
  route_table_id    = aws_route_table.pri-rt-b.id
}

# associate private subnet pri-sub-6b with private route table Pri-rt-b
resource "aws_route_table_association" "pri-sub-6b-with-pri-rt-b" {
  subnet_id         = aws_subnet.pri_sub_6b.id
  route_table_id    = aws_route_table.pri-rt-b.id
}