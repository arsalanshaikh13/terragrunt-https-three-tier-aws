output "endpoint_address" {
  description = "dns address for db instance endpoint"
  value       = aws_db_instance.panda-database.address
}

output "db_endpoint" {
  description = "db instance  endpoint for db instance"
  value = aws_db_instance.panda-database.endpoint
}