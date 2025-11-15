#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

NEW_BLOCK='# https://terragrunt.gruntwork.io/docs/reference/hcl/functions/#get_parent_terragrunt_dir
  required_var_files = ["${get_parent_terragrunt_dir("root")}/configuration/terraform.tfvars"]'

echo "🔍 Processing terragrunt.hcl files under $ROOT_DIR ..."

find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do

  # Skip file if already patched
  if grep -q 'get_parent_terragrunt_dir("root")' "$file"; then
    echo "⚠️  Skipping $file (already patched)"
    continue
  fi

  echo "✏️  Patching $file..."

  awk -v block="$NEW_BLOCK" '
    /terraform[[:space:]]*{/ {in_tf=1}

    # Detect required_var_files inside terraform block
    in_tf && /^[[:space:]]*required_var_files[[:space:]]*=/ {
      print "# " $0              # comment out original required_var_files
      print block                # insert the two new lines
      next                       # skip printing the original line
    }

    # Detect closing brace of terraform block
    in_tf && /^[[:space:]]*}/ {
      in_tf=0
      print "}"                  # print the final terraform closing brace
      next
    }

    { print }
  ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

done

echo "✅ Finished patching all terraform blocks!"
