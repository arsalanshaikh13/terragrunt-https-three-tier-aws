#!/usr/bin/env bash
set -euo pipefail

# Folder argument (optional)
TARGET_DIR="${1:-.}"

cd "$TARGET_DIR"

VARS_FILE="variables.tf"
TFVARS_FILE="terraform.tfvars"

# Start fresh
> "$TFVARS_FILE"


# # Extract variable names and write to terraform.tfvars using Perl syntax regex matching
# grep -oP '(?<=variable\s+")\w+(?=")' "$VARS_FILE" | while read -r varname; do
#   echo "${varname} = " >> "$TFVARS_FILE"
# done

# Extract variable names and write to terraform.tfvars
# grep '^variable' "$VARS_FILE" | sed -E 's/variable[[:space:]]+"([^"]+)".*/\1/' | while read -r varname; do
grep '^variable' "$VARS_FILE" | sed -E 's/variable\s+"([^"]+)".*/\1/' | while read -r varname; do
  echo "${varname} = " >> "$TFVARS_FILE"
done

echo "✅ terraform.tfvars generated successfully at: $TARGET_DIR/$TFVARS_FILE"
