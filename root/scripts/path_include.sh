#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

echo "🔍 Searching for terragrunt.hcl files under $ROOT_DIR ..."

find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
#   if grep -q 'get_parent_terragrunt_dir' "$file"; then
  if grep -q 'path_relative_from_include' "$file"; then
    echo "✏️  Updating $file"
    # Replace all occurrences safely with backup
    # sed -i.bak 's/get_parent_terragrunt_dir/path_relative_from_include/g' "$file"
    sed -i.bak 's/path_relative_from_include("common.hcl")/path_relative_from_include("root")/g' "$file"
  fi
done

echo "✅ Done! All get_parent_terragrunt_dir() calls replaced with path_relative_from_include()."
