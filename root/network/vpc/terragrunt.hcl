

include "root" {
  path   = find_in_parent_folders("common.hcl")
  expose = true

}
include "global_mocks" {
  path   = find_in_parent_folders("global-mocks.hcl")
  expose = true
}

terraform {
  # source = "../../../../modules/app"
  source = "${path_relative_from_include("root")}/modules/network/vpc"

  # You can also specify multiple extra arguments for each use case. Here we configure terragrunt to always pass in the
  # `common.tfvars` var file located by the parent terragrunt config.
  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "destroy"
    ]

    # required_var_files = ["terraform.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/dev/us-east-1/app/app.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/${basename(dirname(dirname(get_terragrunt_dir())))}/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}/app.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/terraform.tfvars"]
    # required_var_files = ["${path_relative_from_include("root")}/configuration/terraform.tfvars"]
    #     required_var_files = ["${dirname(dirname(dirname(get_terragrunt_dir())))}/configuration/terraform.tfvars"]
    # https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#get_parent_terragrunt_dir
    required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]
  }

  # The following are examples of how to specify hooks

  # Before apply or plan, run "echo Foo".
  before_hook "before_hook_1" {
    commands = ["apply", "plan"]
    execute  = ["echo", "Foo"]
  }

  # Before apply, run "echo Bar". Note that blocks are ordered, so this hook will run after the previous hook to
  # "echo Foo". In this case, always "echo Bar" even if the previous hook failed.
  before_hook "before_hook_2" {
    commands     = ["apply"]
    execute      = ["echo", "Bar"]
    run_on_error = true
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
# dependency "backend" {
#   config_path                             = "${get_repo_root()}/backend-tfstate-bootstrap"
#   mock_outputs                            = { vpc_id = "vpc-3a1234abcd5678ef" }
#   mock_outputs_allowed_terraform_commands = ["plan"]
# }
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  plan 
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --  apply -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir network -- destroy -auto-approve
# TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all --working-dir app --   destroy -auto-approve

# SOURCE="network"
#  echo 'vpc security-group iam_role'  | tr ' ' '\n'  | xargs -I {} mv {}  "$SOURCE" ;

# delete same folder/file from each directory
# find . -type f -name ".terraform.lock.hcl" -prune -exec rm -rf {} \;

# copy same folder in to many different folders
# SOURCE_FOLDER="network/security-group"
# echo "s3 rds aws_secret alb asg null_resource asg cloudfront route53" | tr ' ' '\n'  | xargs -I {} cp -r "$SOURCE_FOLDER" {};
