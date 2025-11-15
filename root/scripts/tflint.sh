#!/bin/bash
set -euo pipefail

tflint=$(cat <<'EOF'
# https://terragrunt.gruntwork.io/docs/features/hooks/
plugin "aws" {
  enabled = true
  version = "0.43.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  # Plugin common attributes    
  enabled = true
  # version = "0.13.0"
  # source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset = "recommended"
}
# https://medium.com/cloud-native-daily/how-to-use-tflint-to-check-errors-in-your-terraform-code-c0f0e4c4db41
config {
#Enables module inspection
  call_module_type = "local"
  force = false
}
 
# Disallow deprecated (0.11-style) interpolation
rule "terraform_deprecated_interpolation" {
  enabled = true
}
 
# Disallow legacy dot index syntax.
rule "terraform_deprecated_index" {
  enabled = true
}
 
# Disallow variables, data sources, and locals that are declared but never used.
rule "terraform_unused_declarations" {
  enabled = true
}
 
# Disallow // comments in favor of #.
rule "terraform_comment_syntax" {
  enabled = false
}
 
# Disallow output declarations without description.
rule "terraform_documented_outputs" {
  enabled = true
}
 
# Disallow variable declarations without description.
rule "terraform_documented_variables" {
  enabled = true
}
 
# Disallow variable declarations without type.
rule "terraform_typed_variables" {
  enabled = true
}
 
# Disallow specifying a git or mercurial repository as a module source without pinning to a version.
rule "terraform_module_pinned_source" {
  enabled = true
}
 
# Enforces naming conventions
rule "terraform_naming_convention" {
  enabled = true
 
#Require specific naming structure
variable {
  format = "snake_case"
}
 
# locals {
# format = "snake_case"
# }
 
# output {
# format = "snake_case"
# }
 
#Allow any format
resource {
  format = "none"
}
 
module {
  format = "none"
}
 
data {
  format = "none"
}
 
}
 
# Disallow terraform declarations without require_version.
rule "terraform_required_version" {
  enabled = true
}
 
# Require that all providers have version constraints through required_providers.
rule "terraform_required_providers" {
  enabled = true
}
 
# Ensure that a module complies with the Terraform Standard Module Structure
rule "terraform_standard_module_structure" {
  enabled = true
}
 
# terraform.workspace should not be used with a "remote" backend with remote execution.
rule "terraform_workspace_remote" {
  enabled = true
}
EOF
)


# global_mock=$(cat <<'EOF'
# include "global_mock" {
#   path = find_in_parent_folders("global-mocks.hcl")
#   expose = true
# }

# EOF
# )


# dependency_mock=$(cat <<'EOF'
#   mock_outputs                            = include.global_mock.locals.global_mock_outputs
#   mock_outputs_allowed_terraform_commands = ["plan"]

# EOF

# )

hooks_content=$(cat <<'HOOKS'
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
        if [ $exit_code -gt 0 ]; then
          echo "exit code : $exit_code"
          echo "✅ TFLint completed with issues (non-fatal). Continuing Terragrunt..."
          exit 0
        else
          echo "exit code : $exit_code"
          exit $exit_code
        fi
      EOT
    ]
  }
  after_hook "post_apply_graph" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo 'Running terraform graph'; mkdir -p '${get_terragrunt_dir()}'/graph; terraform graph > '${get_terragrunt_dir()}'/graph/graph-apply.dot"]
  }
  
  error_hook "Display_ERROR" {
    commands = ["plan", "apply", "destroy"]
    execute = ["echo", "Error occured while running the operation!!!"]
  }

  after_hook "post_apply_message" {
    commands = ["apply"]
    execute  = ["bash", "-c", "echo '✅ Resources created successfully'"]
  }
  after_hook "post_destroy" {
    commands = ["destroy"]
    execute  = ["bash", "-c", "echo '✅ Resources deleted successfully'"]
  }
HOOKS
)

# cd terraform
# Folders to process
# copy_order=("hosting" "compute" "database" "permissions" "network")
# copy_order=$(find . -type f -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" \
#                   | xargs -I {} dirname {} \
#                   | sed 's|^\./||')

mapfile -t copy_order < <(
  find . -type f -name "terragrunt.hcl" -not -path "*/.terragrunt-cache/*" \
    | xargs -I {} dirname {} \
    | sed 's|^\./||'
)

# copy_order=("$1")
# echo "copy order list: $copy_order & ${copy_order[@]}"
for folder in "${copy_order[@]}"; do
  echo " found dir : $folder";
  # continue
  rm -f $folder/*tflint* || true
  if [[ -d "root/$folder" ]]; then
    echo "⚠️  Skipping: Folder not found -> $folder"
    continue
  fi

  tflint_path="${folder}/custom.tflint.hcl"
  if [[ ! -f "$tflint_path" ]]; then
    echo "📄 Creating $tflint_path"
    echo "$tflint" > "$tflint_path"
  else
    echo "✅ $tflint_path already exists, skipping"
  fi

  tf_file="${folder}/terragrunt.hcl"
  if [[ ! -f "$tf_file" ]]; then
      echo "⚠️  Skipping: File not found -> $tf_file"
      continue
  fi

  
#   # Check if one of the hooks already exists
#   if grep -q 'mock_outputs' "$tf_file"; then
#       echo "✅ dependency mock outputs key already exist in $tf_file"
#       # continue
#   else
#     # appending global_mock lines to terragrunt.hcl
#     echo "appending dependency mock keys to terragrunt.hcl file"

#     awk -v depend_mock_var="$dependency_mock" '
#         BEGIN { in_depend_block = 0 }
#         /dependency\s+"(\w+)"\s*\{/ { in_depend_block = 1 }
#         in_depend_block && /^}/ {
#         print depend_mock_var
#         in_depend_block = 0
#         }
#         { print }
#        ' "$tf_file" > "${tf_file}.tmp" && mv "${tf_file}.tmp" "$tf_file"
#   fi

  
#   if grep -q 'include "global_mock"' "$tf_file"; then
#       echo "✅ global mock include block already exist in $tf_file"

#   else

#     echo "appending global mock include block to terragrunt.hcl file"

#     awk -v include_block="$global_mock" '
#         BEGIN { already = 0 }
#         # Skip if the include block already exists (idempotent)
#         /include\s+"global_mock"/ { 
#         already = 1 
#         }

#         # When we see the first dependency line and the include hasn’t been added yet
#         /^\s*terraform\s+("\w*")*\s*\{/ && !already {
#             print include_block
#             print ""
#             already = 1
#         }
#         { print }
#        ' "$tf_file" > "${tf_file}.tmp" && mv "${tf_file}.tmp" "$tf_file"

#     # no need to append since we are inserting before dependency block
#     # echo "$global_mock" >> "$tf_file"
#   fi

  # Check if one of the hooks already exists
  if grep -q 'before_hook "pre_validate"' "$tf_file"; then
      echo "✅ Hooks already exist in $tf_file"
      continue
  fi

  echo "🔧 Appending hooks to $tf_file"
  
  # Use awk for cleaner injection
  awk -v hooks="$hooks_content" '
  BEGIN {
      in_tf = 0
      brace_count = 0
      done = 0
  }
  /terraform\s*\{/ && !done {
      in_tf = 1
      brace_count = 1
      print
      next
  }
  in_tf {
      if (/\{/) brace_count++
      if (/\}/) brace_count--
      
      if (brace_count == 0 && /^\}/ && !done) {
          print hooks
          done = 1
      }
  }
  { print }
  ' "$tf_file" > "${tf_file}.tmp" && mv "${tf_file}.tmp" "$tf_file"
  
  echo "✅ Hooks injected into $tf_file"

  
  echo "✅ Hooks appended successfully to $tf_file"
#   cd $folder
#   rm -f backend.tf data.tf providers.tf 2>&1 | tee ../../log.txt
#   cd ..
done
