

include "root" {
  path = find_in_parent_folders("common.hcl")
}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}


terraform {
  # source = "../../../../modules/app"
  source = "${path_relative_from_include("root")}/modules/hosting/cloudfront"

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

dependency "vpc" {
  # config_path                             = "../../network/vpc"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/network/vpc"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "acm" {
  # config_path                             = "../../permissions/acm"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/permissions/acm"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
dependency "alb" {
  # config_path                             = "../../compute/alb"
  config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/compute/alb"
  mock_outputs                            = include.global_mocks.locals.global_mock_outputs
  mock_outputs_allowed_terraform_commands = ["plan"]
}
# dependency "asg" {
#   # config_path                             = "../../compute/alb"
#   config_path                             = "${dirname(dirname(get_terragrunt_dir()))}/compute/asg"
#   mock_outputs                            = include.global_mocks.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }

inputs = {
  project_name        = dependency.vpc.outputs.project_name
  acm_certificate_arn = dependency.acm.outputs.acm_certificate_arn
  alb_domain_name     = dependency.alb.outputs.alb_dns_name

}
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve
