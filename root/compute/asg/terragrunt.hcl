

include "root" {
  path   = find_in_parent_folders("common.hcl")
  expose = true
}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}
locals {
  region = include.root.locals.region
}

terraform {
  # source = "../../../../modules/app"
  source = "${path_relative_from_include("root")}/modules/compute/asg"

  # You can also specify multiple extra arguments for each use case. Here we configure terragrunt to always pass in the
  # `common.tfvars` var file located by the parent terragrunt config.
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "destroy"
    ]

    # required_var_files = ["terraform.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/dev/us-east-1/app/app.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/${basename(dirname(dirname(get_terragrunt_dir())))}/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}/app.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/terraform.tfvars"]
    #     required_var_files = ["${dirname(dirname(dirname(get_terragrunt_dir())))}/configuration/terraform.tfvars"]
    # https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#get_parent_terragrunt_dir
    required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]
  }

  # The following are examples of how to specify hooks
  # https://terragrunt.gruntwork.io/docs/features/hooks/

  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }

  before_hook "tflint" {
    commands = ["plan"]
    execute = [
      "bash", "-c",
      <<-EOT
        tflint --recursive --minimum-failure-severity=error --config "${get_terragrunt_dir()}/custom.tflint.hcl"
        exit_code=$?
        echo "exit code : $exit_code"
        exit $exit_code
      EOT
    ]
  }
  after_hook "post_apply_graph" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo 'Running terraform graph'; mkdir -p '${get_terragrunt_dir()}'/graph; terraform graph > '${get_terragrunt_dir()}'/graph/graph-apply.dot"]
  }
  after_hook "post_apply_message" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Resources created successfully'"]
  }

  error_hook "Display ERROR" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["echo", "Error occured while running the operation!!!"]
    on_errors = [
      ".*",
    ]
  }

  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}

# Generate extended provider block (adds local & null)
generate "provider_compute" {
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
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
  }
}
provider "aws" {
  region = "${local.region}"
}

EOF
}


dependency "vpc" {
  # config_path                             = "../../network/vpc"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/vpc"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "security-group" {
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/security-group"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "rds" {
  # config_path                             = "../../database/rds"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/database/rds"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "aws_secret" {
  # config_path                             = "../../database/aws_secret"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/database/aws_secret"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "iam_role" {
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/permissions/iam_role"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "alb" {
  # config_path                             = "../alb"
  config_path                             = "${dirname(get_terragrunt_dir())}/alb"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "null_resource" {
  # config_path                             = "../null_resource"
  config_path                             = "${dirname(get_terragrunt_dir())}/null_resource"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

dependency "s3" {
  # config_path                             = "../../s3"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/s3"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}

inputs = {
  project_name                    = dependency.vpc.outputs.project_name
  pri_sub_3a_id                   = dependency.vpc.outputs.pri_sub_3a_id
  pri_sub_4b_id                   = dependency.vpc.outputs.pri_sub_4b_id
  pri_sub_5a_id                   = dependency.vpc.outputs.pri_sub_5a_id
  pri_sub_6b_id                   = dependency.vpc.outputs.pri_sub_6b_id
  client_sg_id                    = dependency.security-group.outputs.client_sg_id
  server_sg_id                    = dependency.security-group.outputs.server_sg_id
  tg_arn                          = dependency.alb.outputs.tg_arn
  internal_tg_arn                 = dependency.alb.outputs.internal_tg_arn
  internal_alb_dns_name           = dependency.alb.outputs.internal_alb_dns_name
  s3_ssm_cw_instance_profile_name = dependency.iam_role.outputs.s3_ssm_cw_instance_profile_name
  db_dns_address                  = dependency.rds.outputs.endpoint_address
  db_endpoint                     = dependency.rds.outputs.db_endpoint
  db_secret_name                  = dependency.aws_secret.outputs.db_secret_name
  bucket_name                     = dependency.s3.outputs.panda_bucket_name
  frontend_ami_id                 = dependency.null_resource.outputs.frontend_ami_id
  backend_ami_id                  = dependency.null_resource.outputs.backend_ami_id

}
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve
