# iam role and policy for S3 and SSM
# resource "aws_iam_role" "s3_ssm_role" {
resource "aws_iam_role" "s3_ssm_CW_role" {
  name = "S3-SSM-CW-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
  tags = {
    Name = "S3-SSM-Role"
    Purpose = "Allow EC2 to access S3 and use SSM agent"
  }

}

resource "aws_iam_role_policy_attachment" "ssm_core_attach" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "s3_readonly_attach" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "secret_manager-ReadWrite" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
resource "aws_iam_role_policy_attachment" "ssmparameter_read_only" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess"
}
resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attachment" {
  # role       = aws_iam_role.s3_ssm_role.name
  role       = aws_iam_role.s3_ssm_CW_role.name
  policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn 
  # arn:aws:iam::513410254332:policy/log-group-log-streams
}


# resource "aws_iam_instance_profile" "s3_ssm_profile" {
resource "aws_iam_instance_profile" "s3_ssm_cw_profile" {
  # name = "S3-SSM-Profile"
  name = "S3-SSM-CW-Profile"
  # role = aws_iam_role.s3_ssm_role.name
  role = aws_iam_role.s3_ssm_CW_role.name
}

## using for each to set iam role policy attachment
# locals {
#   policy_arns = [
#     "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
#     "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
#   ]
# }

# resource "aws_iam_role_policy_attachment" "s3_ssm_attach" {
#   for_each   = toset(local.policy_arns)
#   role       = aws_iam_role.s3_ssm_role.name
#   policy_arn = each.key
# }



# Iam role for setting up cloudwatch log through cloudwatch agent
# resource "aws_iam_role" "cloudwatch_agent_role" {
#   name = "cloudwatch-agent-role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Action = "sts:AssumeRole",
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# policy to attach with s3 and ssm role 
# this policy can be attach standalone to cloudwatch role as well
resource "aws_iam_policy" "cloudwatch_agent_policy" {
  name        = "cloudwatch-agent-policy"
  description = "Policy for EC2 instances to send logs to CloudWatch"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:GetLogEvents",
                "logs:DeleteLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*:log-stream:*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": [
                "logs:ListTagsLogGroup",
                "logs:GetLogRecord",
                "logs:DeleteLogGroup",
                "logs:DescribeLogStreams",
                "logs:DescribeMetricFilters",
                "logs:GetLogGroupFields",
                "logs:CreateLogGroup"
            ],
            "Resource": "arn:aws:logs:*:*:log-group:*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogDelivery",
                "logs:DescribeLogGroups",
                "logs:ListLogGroupsForQuery",
                "logs:GetLogDelivery",
                "logs:ListLogGroups",
                "logs:DescribeDestinations"
            ],
            "Resource": "*"
        }
      ]
    }
  )
}

# this attachment is only for cloudwatch agent specific only
# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_attachment" {
#   role       = aws_iam_role.cloudwatch_agent_role.name
#   policy_arn = aws_iam_policy.cloudwatch_agent_policy.arn
# }

# resource "aws_iam_instance_profile" "cloudwatch_agent_profile" {
#   name = "cloudwatch-agent-profile"
#   role = aws_iam_role.cloudwatch_agent_role.name
# }



# VPC Flow logs
# 1. Create an S3 bucket for storing VPC Flow Logs
resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "vpc-flow-log-s3-bucket-panda" # Replace with a unique bucket name
  # region = "us-east-1"
  # acl    = "private" # deprecated use below resource
  force_destroy = true

  # # Optional: Enable server-side encryption for the bucket
  # deprecated used the below resource
  # server_side_encryption_configuration {
  #   rule {
  #     apply_server_side_encryption_by_default {
  #       sse_algorithm = "AES256"
  #     }
  #   }
  # }
}

resource "aws_s3_bucket_ownership_controls" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "acl" {
  depends_on = [aws_s3_bucket_ownership_controls.vpc_flow_logs]

  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  acl    = "private"
}
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration
resource "aws_s3_bucket_server_side_encryption_configuration" "SSE_config" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id

  rule {
    bucket_key_enabled = false
    apply_server_side_encryption_by_default {
      sse_algorithm     = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.bucket

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# s3 bucket policy
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.bucket
  # policy = data.aws_iam_policy_document.vpc_flow_logs_policy.json
  # https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs-s3-permissions.html
  policy = jsonencode({
    "Version":"2012-10-17",		 	 	 
    "Statement": [
        {
            "Sid": "AWSLogDeliveryWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}",
                    "s3:x-amz-acl": "bucket-owner-full-control"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
                }
            }
        },
        {
            "Sid": "AWSLogDeliveryAclCheck",
            "Effect": "Allow",
            "Principal": {
                "Service": "delivery.logs.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.vpc_flow_logs_bucket.arn}",
            "Condition": {
                "StringEquals": {
                    "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
                },
                "ArnLike": {
                    "aws:SourceArn": "arn:aws:logs:us-east-1:${data.aws_caller_identity.current.account_id}:*"
                }
            }
        }
    ]
})
}


# Data source to get the current AWS account ID
data "aws_caller_identity" "current" {}

# # 4. Create the VPC Flow Log
resource "aws_flow_log" "example_vpc_flow_log" {
  log_destination      = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type = "s3"
  # iam_role_arn         = aws_iam_role.vpc_flow_logs_role.arn
  traffic_type         = "ALL" # or "ACCEPT", "REJECT"
  vpc_id               = var.vpc_id # Replace with your VPC ID
}


# resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
#   bucket = "your-vpc-flow-logs-bucket-name"
#   acl    = "private"

#   # Optional: Enable server-side encryption with KMS
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         kms_master_key_id = aws_kms_key.vpc_flow_logs_key.arn
#         sse_algorithm     = "aws:kms"
#       }
#     }
#   }

#   tags = {
#     Name = "VPC Flow Logs Bucket"
#   }
# }


# # Optional: KMS Key for S3 bucket encryption
# resource "aws_kms_key" "vpc_flow_logs_key" {
#   description             = "KMS key for VPC Flow Logs S3 bucket encryption"
#   deletion_window_in_days = 7
#   policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Sid    = "Enable IAM User Permissions",
#         Effect = "Allow",
#         Principal = {
#           AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
#         },
#         Action   = "kms:*",
#         Resource = "*"
#       },
#       {
      #   Sid    = "Allow administration of the key"
      #   Effect = "Allow"
      #   Principal = {
      #     AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/Arsalan13IAM"
      #   },
      #   Action = [
      #     "kms:ReplicateKey",
      #     "kms:Create*",
      #     "kms:Describe*",
      #     "kms:Enable*",
      #     "kms:List*",
      #     "kms:Put*",
      #     "kms:Update*",
      #     "kms:Revoke*",
      #     "kms:Disable*",
      #     "kms:Get*",
      #     "kms:Delete*",
      #     "kms:ScheduleKeyDeletion",
      #     "kms:CancelKeyDeletion"
      #   ],
      #   Resource = "*"
      # },
#       {
#         Sid       = "Allow VPC Flow Logs to use the key",
#         Effect    = "Allow",
#         Principal = {
#           Service = "delivery.logs.amazonaws.com"
#         },
#         Action = [
#           "kms:Encrypt",
#           "kms:Decrypt",
#           "kms:ReEncrypt*",
#           "kms:GenerateDataKey*",
#           "kms:DescribeKey"
#         ],
#         Resource = "*"
#       }
#     ]
#   })
# }

# data "aws_caller_identity" "current" {}



# panda cloud vpc flow log policy in s3 bucket
# {
#     "Version": "2012-10-17",
#     "Id": "AWSLogDeliveryWrite20150319",
#     "Statement": [
#         {
#             "Sid": "AWSLogDeliveryWrite1",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "delivery.logs.amazonaws.com"
#             },
#             "Action": "s3:PutObject",
#             "Resource": "arn:aws:s3:::panda-vpc-flow/AWSLogs/513410254332/*",
#             "Condition": {
#                 "StringEquals": {
#                     "aws:SourceAccount": "513410254332",
#                     "s3:x-amz-acl": "bucket-owner-full-control"
#                 },
#                 "ArnLike": {
#                     "aws:SourceArn": "arn:aws:logs:us-east-1:513410254332:*"
#                 }
#             }
#         },
#         {
#             "Sid": "AWSLogDeliveryAclCheck1",
#             "Effect": "Allow",
#             "Principal": {
#                 "Service": "delivery.logs.amazonaws.com"
#             },
#             "Action": "s3:GetBucketAcl",
#             "Resource": "arn:aws:s3:::panda-vpc-flow",
#             "Condition": {
#                 "StringEquals": {
#                     "aws:SourceAccount": "513410254332"
#                 },
#                 "ArnLike": {
#                     "aws:SourceArn": "arn:aws:logs:us-east-1:513410254332:*"
#                 }
#             }
#         }
#     ]
# }




# clone parallax, clone aws sample app, clone lirw and upload to s3 and host website from s3
# incorporate vpc flow logs, cloudwatch alarm notification through sns, ssl/route53/tls/https/certificate from acm
# lets encrypt to use nginx
# add vpc endpoint and vpc private link/ transit gateway vpc peering into terraform
# learn ansible to configure software
# terraform
# make module based configuration for lirw app, integrate ssm/secret manager into the app
# use existing modules from terraform
# go through terraform series from piyush/rahul/abhishek
# blog , procedure methodology to reproduce my project workflow 
# making ecs, eks cluster using terraform

# s3 with route 53
# lirw with module based terraform
# lirw with folder based module based terraform
# maximizing for speed this time
# lirw with packer-ssh, https/api-alb, sns email notification on cloudwatch alarm, with module-folder based configuration

# folder structure
# network
# data.tf(data "terraform_remote_state")
# main.tf
# variables.tf
# output.tf
#   modules
#     vpc
#       main.tf
#       variables.tf
#       output.tf
# compute
# data.tf(data "terraform_remote_state")
# main.tf
# variables.tf
# output.tf
#   modules
#     aws_instance
#       main.tf
#       variables.tf
#       output.tf
#     alb
#       main.tf
#       variables.tf
#       output.tf
#     asg
#       main.tf
#       variables.tf
#       output.tf

# setup.sh
# cd network
# terraform apply
# cd ../compute
# terraform apply