resource "aws_secretsmanager_secret" "db_secret" {
    name        = "${var.project_name}-secret"
    description = "Database credentials for my application"
    # kms_key_id  = "alias/aws/secretsmanager" # Or a custom KMS key ARN
    recovery_window_in_days = 0 #force delete,
    tags = {
      Name = "${var.project_name}-secret"
    }
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
    secret_id     = aws_secretsmanager_secret.db_secret.id
    secret_string = jsonencode({
        DB_HOST     = "${var.db_dns_address}"
        DB_USERNAME = "${var.db_username}"
        DB_PASSWORD = "${var.db_password}"
        DB_NAME     = "${var.db_name}"
    })
}


resource "aws_ssm_parameter" "db_host" {
  name        = "DB_HOST"
  description = "database dns address"
  type        = "String"
  value       = var.db_dns_address

  tags = {
    environment = "dev"
  }
}
resource "aws_ssm_parameter" "db_username" {
  name        = "DB_USERNAME"
  description = "database username"
  type        = "String"
  value       = var.db_username

  tags = {
    environment = "dev"
  }
}
resource "aws_ssm_parameter" "db_password" {
  name        = "DB_PASSWORD"
  description = "database password"
  type        = "SecureString"
  value       = var.db_password

  tags = {
    environment = "dev"
  }
}
resource "aws_ssm_parameter" "db_name" {
  name        = "DB_NAME"
  description = "database name"
  type        = "String"
  value       = var.db_name

  tags = {
    environment = "dev"
  }
}