#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

BLOCK='include "global_mocks" {
  path = find_in_parent_folders("global-mocks.hcl")
}'

echo "🔍 Searching for terragrunt.hcl files in $ROOT_DIR ..."

find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
  if grep -q 'include "global_mocks"' "$file"; then
    echo "⚠️  Skipping $file (already contains global_mocks)"
    continue
  fi

  if grep -q 'include "root"' "$file"; then
    echo "✏️  Inserting global_mocks block into $file"
    # Insert after the include "root" block and before terraform {
    awk -v block="$BLOCK" '
      /include[[:space:]]*"root"[[:space:]]*{/ {print; in_root=1; next}
      in_root && /^\}/ {print; print block; in_root=0; next}
      {print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  else
    echo "⚠️  Skipping $file (no include \"root\" found)"
  fi
done

echo "✅ Done inserting global_mocks blocks."

# if grep -q 'include "root"' "$file"; then
#     echo "✏️  Inserting global_mocks block into $file"
#     # Insert after the include "root" block and before terraform {
#     awk -v block="$BLOCK" '
#       /^terraform[[:space:]]*{/ && !inserted {print block; inserted=1}      
#       {print}
#     ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
#   else
#     echo "⚠️  Skipping $file (no include \"root\" found)"
#   fi

# set -euo pipefail

# ROOT_DIR="${1:-.}"

# BLOCK='include "global_mocks" {
#   path = find_in_parent_folders("global-mocks.hcl")
# }'

# echo "🔍 Searching for terragrunt.hcl files under $ROOT_DIR ..."

# find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
#   # Skip if already has global_mocks
#   if grep -q 'include "global_mocks"' "$file"; then
#     echo "⚠️  Skipping $file (already contains global_mocks)"
#     continue
#   fi

#   if grep -q 'include "root"' "$file"; then
#     echo "✏️  Adding global_mocks block in $file"

#     awk -v block="$BLOCK" '
#       BEGIN {inserted=0}
#       {
#         print $0
#         # Match the end of include "root" block and insert once
#         if ($0 ~ /^}/ && prev ~ /include[[:space:]]*"root"[[:space:]]*{/) {
#           print ""
#           print block
#           print ""
#           inserted=1
#         }
#         prev=$0
#       }
#       END {
#         # if file had no closing brace after include root, do nothing special
#       }
#     ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
#   else
#     echo "⚠️  Skipping $file (no include \"root\" block found)"
#   fi
# done

# echo "✅ Done! global_mocks block added once per file."
