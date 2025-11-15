# output "s3_ssm_role_name" {
output "s3_ssm_cw_role_name" {
  description = "IAM role name for S3 and SSM access"
  # value       = aws_iam_role.s3_ssm_role.name
  value       = aws_iam_role.s3_ssm_CW_role.name
}
# output "s3_ssm_instance_profile_name" {
output "s3_ssm_cw_instance_profile_name" {
  description = "IAM role name for S3 and SSM access"
  # value       = aws_iam_instance_profile.s3_ssm_profile.name
  value       = aws_iam_instance_profile.s3_ssm_cw_profile.name
}

# for cloudwatch specific agent role only
# output "cloudwatch_agent_role" {
#   description = "IAM role name for S3 and SSM access"
#   value       = aws_iam_role.cloudwatch_agent_role.name
# }
# output "cloudwatch_agent_profile_name" {
#   description = "IAM role name for S3 and SSM access"
#   value       = aws_iam_instance_profile.cloudwatch_agent_profile.name
# }


# # https://ryandeangraham.medium.com/terraforming-vpc-flow-logs-0b9defb03d67
# resource "aws_s3_bucket" "vpc_flow_logs" {
#   bucket = "mycompany-vpc-flow-logs"
# }

# locals {
#   allowed_accounts = [
#     "012345678912"
#   ]
# }

# resource "aws_s3_bucket_ownership_controls" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.id
#   rule {
#     object_ownership = "BucketOwnerPreferred"
#   }
# }

# resource "aws_s3_bucket_acl" "vpc_flow_logs" {
#   depends_on = [aws_s3_bucket_ownership_controls.vpc_flow_logs]

#   bucket = aws_s3_bucket.vpc_flow_logs.id
#   acl    = "private"
# }

# resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.bucket

#   rule {
#     bucket_key_enabled = false
#     apply_server_side_encryption_by_default {
#       sse_algorithm = "AES256"
#     }
#   }
# }

# resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.bucket

#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
# }

# resource "aws_s3_bucket_policy" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.bucket
#   policy = data.aws_iam_policy_document.vpc_flow_logs_policy.json
# }

# data "aws_iam_policy_document" "vpc_flow_logs_policy" {
#   statement {
#     sid       = "AWSLogDeliveryWrite"
#     actions   = ["s3:PutObject"]
#     resources = ["${aws_s3_bucket.vpc_flow_logs.arn}/*"]

#     principals {
#       type        = "Service"
#       identifiers = ["delivery.logs.amazonaws.com"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values   = local.allowed_accounts
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "s3:x-amz-acl"
#       values   = ["bucket-owner-full-control"]
#     }
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"
#       values   = [for account in local.allowed_accounts : "arn:aws:logs:us-east-1:${account}:*"]
#     }
#   }

#   statement {
#     sid       = "AWSLogDeliveryAclCheck"
#     actions   = ["s3:GetBucketAcl", "s3:ListBucket"]
#     resources = [aws_s3_bucket.vpc_flow_logs.arn]

#     principals {
#       type        = "Service"
#       identifiers = ["delivery.logs.amazonaws.com"]
#     }
#     condition {
#       test     = "StringEquals"
#       variable = "aws:SourceAccount"
#       values   = local.allowed_accounts
#     }
#     condition {
#       test     = "ArnLike"
#       variable = "aws:SourceArn"
#       values   = [for account in local.allowed_accounts : "arn:aws:logs:us-east-1:${account}:*"]
#     }
#   }

#   statement {
#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
#     effect = "Deny"
#     actions = [
#       "s3:*",
#     ]
#     resources = [
#       aws_s3_bucket.vpc_flow_logs.arn,
#       "${aws_s3_bucket.vpc_flow_logs.arn}/*",
#     ]

#     condition {
#       test     = "Bool"
#       variable = "aws:SecureTransport"
#       values   = ["false"]
#     }
#   }
# }

# resource "aws_s3_bucket_versioning" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.bucket

#   versioning_configuration {
#     status = "Enabled"
#   }
# }

# resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs" {
#   bucket = aws_s3_bucket.vpc_flow_logs.bucket

#   rule {
#     id     = "rule-1"
#     status = "Enabled"

#     noncurrent_version_expiration {
#       noncurrent_days = 7
#     }

#     abort_incomplete_multipart_upload {
#       days_after_initiation = 1
#     }

#     expiration {
#       days = 90
#     }
#   }
# }


# resource "aws_flow_log" "this" {
#   log_destination      = "arn:aws:s3:::mycompany-vpc-flow-logs"
#   log_destination_type = "s3"
#   traffic_type         = "ALL"
#   log_format           = "$${version} $${account-id} $${action} $${interface-id} $${srcaddr} $${dstaddr} $${srcport} $${dstport} $${protocol} $${packets} $${bytes} $${start} $${end} $${log-status} $${vpc-id} $${subnet-id} $${instance-id} $${tcp-flags} $${type} $${pkt-srcaddr} $${pkt-dstaddr} $${region} $${az-id} $${sublocation-type} $${sublocation-id} $${pkt-src-aws-service} $${pkt-dst-aws-service} $${flow-direction} $${traffic-path}"
#   vpc_id               = aws_vpc.this.id
#   destination_options {
#     file_format                = "parquet"
#     hive_compatible_partitions = true
#     per_hour_partition         = true
#   }
#   tags = {
#     Name = "myvpc-flowlogs"
#   }
# }