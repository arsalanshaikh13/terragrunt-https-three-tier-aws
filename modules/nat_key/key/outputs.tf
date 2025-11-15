output "key_name" {
  value = aws_key_pair.client_key.key_name
}
output "server_key_name" {
  value = aws_key_pair.server_key.key_name
}