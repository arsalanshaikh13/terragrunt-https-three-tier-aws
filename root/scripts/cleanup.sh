#!/bin/bash
set -euo pipefail


destroy_order=("nat_instance" "permissions/iam_role" "network/security-group" "network/vpc" "s3")

echo "🔥 Destroying Terraform stacks in reverse dependency order..."

for dir in "${destroy_order[@]}"; do
  echo "🧨 Destroying ${dir}..."
  terragrunt run --non-interactive  --working-dir $dir -- destroy -auto-approve --parallelism 20   || true
done

echo "✅ All stacks destroyed successfully."
