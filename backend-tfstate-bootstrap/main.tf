

resource "aws_dynamodb_table" "tf_locks" {
  name         = var.dynamodb_table
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Lock Table"
    Environment = "prod"
  }
}

resource "aws_s3_bucket" "tf_state" {
  bucket = var.backend_bucket_name
  #   acl    = "private"
  # https://dev.to/the_cozma/terraform-handling-the-deletion-of-a-non-empty-aws-s3-bucket-3jg3
  force_destroy = true
  #   lifecycle {
  #     prevent_destroy = true
  #   }

  tags = {
    Name        = "Terraform State Bucket"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# output "backend_bucket_name" {
#   value = aws_s3_bucket.tf_state.bucket
# }

# output "dynamodb_table" {
#   value = aws_dynamodb_table.tf_locks.name
# }
# output "region" {
#   value = aws_s3_bucket.tf_state.region
# }