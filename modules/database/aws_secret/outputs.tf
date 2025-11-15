output "db_secret_id" {
    value = aws_secretsmanager_secret.db_secret.id
}
output "db_secret_name" {
    value = aws_secretsmanager_secret.db_secret.name
}