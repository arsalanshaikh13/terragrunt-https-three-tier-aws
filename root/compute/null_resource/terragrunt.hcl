

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
  # original_dir = "${get_original_terragrunt_dir()}"
  # frontend_ami_file = "${local.original_dir}/modules/asg/ami_ids/frontend_ami.txt"
  ami_folder        = "${get_parent_terragrunt_dir("root")}/modules/compute/asg/ami_ids"
  frontend_ami_file = "${local.ami_folder}/frontend_ami.txt"
  backend_ami_file  = "${local.ami_folder}/backend_ami.txt"
  packer_folder     = "${get_parent_terragrunt_dir("root")}/packer"
  frontend_manifest = "${local.packer_folder}/frontend/manifest.json"
  backend_manifest  = "${local.packer_folder}/backend/manifest.json"
}
terraform {
  # source = "../../../../modules/app"
  source = "${path_relative_from_include("root")}/modules/compute/null_resource_packer"

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




  before_hook "delete_AMI" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
      export frontend_ami_file="${local.frontend_ami_file}";
      export backend_ami_file="${local.backend_ami_file}";
      export region="${local.region}"
      # chmod +x ${get_terragrunt_dir()}/delete_AMI.sh;
      # cd ${get_terragrunt_dir()};
      chmod +x delete_AMI.sh;
      ./delete_AMI.sh;
      EOT    
    ]
  }

  after_hook "delete_AMI_manifest_file" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
      # # Clear AMI IDs folder if it exists
      export frontend_manifest_file="${local.frontend_manifest}";
      export backend_manifest_file="${local.backend_manifest}";
      echo " frontend and backend mainifest files: $frontend_manifest_file &&& $backend_manifest_file"
      if [[ -f "$frontend_manifest_file" || -f "$backend_manifest_file" ]]; then
        echo "Clearing AMI IDs manifest files"
        rm -f "$backend_manifest_file";
        rm -f "$frontend_manifest_file";
      fi
      EOT
    ]
  }
  # https://developer.hashicorp.com/terraform/language/expressions/strings#indented-heredocs
  after_hook "delete_AMI_folder" {
    commands = ["destroy"]
    execute = [
      "bash", "-c",
      <<-EOT
      # # Clear AMI IDs folder if it exists
      if [ -d "${local.ami_folder}" ]; then
        echo "Clearing AMI IDs folder"
        rm -rf "${local.ami_folder}"
      fi
      EOT
    ]
  }

  before_hook "pre_fmt" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform format'; terraform fmt --recursive"]
  }
  before_hook "pre_validate" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo 'Running terraform validate'; terraform validate"]
  }
  error_hook "Display ERROR" {
    commands = ["plan", "apply", "destroy"]
    execute  = ["echo", "Error occured while running the operation!!!"]
    on_errors = [
      ".*",
    ]
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
  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
}

# Generate extended provider block (adds local & null)
generate "provider_null_resource" {
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
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}
provider "aws" {
  region = "${local.region}"
}

EOF
}

# dependency "vpc" {
#   # config_path                             = "../../network/vpc"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/vpc"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }

# dependency "security-group" {
#   # config_path                             = "../../security-group/vpc"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/security-group"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }

# dependency "rds" {
#   # config_path                             = "../../database/rds"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/database/rds"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# dependency "aws_secret" {
#   # config_path                             = "../../database/aws_secret"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/database/aws_secret"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# dependency "iam_role" {
#   # config_path                             = "../../database/rds"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/permissions/iam_role"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# dependency "s3" {
#   # config_path                             = "../../s3"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/s3"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# dependency "alb" {
#   # config_path                             = "../alb"
#   config_path                             = "${dirname(get_terragrunt_dir())}/alb"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }


# inputs = {
#   vpc_id        = dependency.vpc.outputs.vpc_id
#   pub_sub_1a_id = dependency.vpc.outputs.pub_sub_1a_id
#   # Get RDS details from Terraform state
#   endpoint_address                = dependency.rds.outputs.endpoint_address
#   db_sg_id                        = dependency.security-group.outputs.db_sg_id
#   s3_ssm_cw_instance_profile_name = dependency.iam_role.outputs.s3_ssm_cw_instance_profile_name
#   db_secret_name                  = dependency.aws_secret.outputs.db_secret_name
#   internal_alb_dns_name           = dependency.alb.outputs.internal_alb_dns_name
#   panda_bucket_name               = dependency.s3.outputs.panda_bucket_name
#   # packer_folder                   = "${path_relative_from_include("root")}/packer"
#   packer_folder = "${local.packer_folder}"

# }
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve
