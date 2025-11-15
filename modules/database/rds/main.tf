
resource "aws_db_subnet_group" "db-subnet" {
  name       = var.db_sub_name
  subnet_ids = [var.pri_sub_7a_id, var.pri_sub_8b_id] # Replace with your private subnet IDs
}

resource "aws_db_instance" "panda-database" {
  identifier              = var.db_identifier
  engine                  = var.db_engine
  engine_version          = var.db_version
  instance_class          = var.db_instance_type
  username                = var.db_username
  password                = var.db_password
  allocated_storage       = var.db_storage_volume
  storage_type            = var.db_storage_type
  multi_az                = false
  storage_encrypted       = false
  publicly_accessible     = false
  skip_final_snapshot     = true
  backup_retention_period = var.retention_period

  vpc_security_group_ids = [var.db_sg_id] # Replace with your desired security group ID

  db_subnet_group_name = aws_db_subnet_group.db-subnet.name

  tags = {
    Name = "${var.db_name}"
  }
}