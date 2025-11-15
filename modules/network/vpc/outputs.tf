output "region" {
  value = var.region
}

output "project_name" {
  value = var.project_name
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "vpc_cidr_block" {
  value = aws_vpc.vpc.cidr_block
}

output "pub_sub_1a_id" {
  value = aws_subnet.pub_sub_1a.id
}
output "pub_sub_2b_id" {
  value = aws_subnet.pub_sub_2b.id
}
output "pri_sub_3a_id" {
  value = aws_subnet.pri_sub_3a.id
}

output "pri_sub_4b_id" {
  value = aws_subnet.pri_sub_4b.id
}

output "pri_sub_5a_id" {
  value = aws_subnet.pri_sub_5a.id
}

output "pri_sub_6b_id" {
    value = aws_subnet.pri_sub_6b.id 
}
output "pri_sub_7a_id" {
    value = aws_subnet.pri_sub_7a.id 
}
output "pri_sub_8b_id" {
    value = aws_subnet.pri_sub_8b.id 
}

output "igw_id" {
    value = aws_internet_gateway.internet_gateway
}
output "pri_rt_a_id" {
    value = aws_route_table.pri-rt-a.id 
}
output "pri_rt_b_id" {
    value = aws_route_table.pri-rt-b.id 
}
