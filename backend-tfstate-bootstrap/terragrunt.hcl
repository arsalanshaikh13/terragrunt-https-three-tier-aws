# backend-tfstate-bootstrap/terragrunt.hcl
terraform {
  source = "./"

  extra_arguments "custom_vars" {
    commands = [
      "apply",
      "plan",
      "destroy"
    ]

    # required_var_files = ["terraform.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/dev/us-east-1/app/app.tfvars"]
    # required_var_files = ["${get_parent_terragrunt_dir()}/configuration/${basename(dirname(dirname(get_terragrunt_dir())))}/${basename(dirname(get_terragrunt_dir()))}/${basename(get_terragrunt_dir())}/app.tfvars"]
    required_var_files = ["${get_repo_root()}/configuration/terraform.tfvars"]
  }
  # Run automatically before any other folder
  before_hook "pre_plan" {
    commands = ["plan"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB planned successfully'"]
  }
  before_hook "pre_apply" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB is being created'"]
  }
  after_hook "post_apply" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB is created successfully '"]
  }
  after_hook "post_backend_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Terraform backend bucket and DynamoDB deleted successfully'"]
  }

}

