
locals {

  backend_hcl         = read_terragrunt_config("${get_repo_root()}/configuration/backend.hcl")
  region              = local.backend_hcl.locals.region
  backend_bucket_name = local.backend_hcl.locals.backend_bucket_name
  dynamodb_table      = local.backend_hcl.locals.dynamodb_table
}

#  Automatically generate provider.tf for all subfolders
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
    backend  "s3"{
    bucket         = "${local.backend_bucket_name}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "${local.dynamodb_table}"
    encrypt        = true
    use_lockfile   = true
  }
}
EOF
}
# Automatically generate provider.tf for all subfolders
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "~> 1.13.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.67.0"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}

# generate "debug" {
#   path = "debug_outputs.txt"
#   if_exists = "overwrite"
#   contents = <<EOF
#   terragrunt_dir: ${get_terragrunt_dir()}

# original_terragrunt_dir: ${get_original_terragrunt_dir()}

# get_repo_root: ${get_repo_root()}

# get_parent_terragrunt_dir: ${get_parent_terragrunt_dir()}

# get_working_dir: ${get_working_dir()}
# EOF
# }

