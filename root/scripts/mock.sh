#!/usr/bin/env bash
set -euo pipefail

# Optional: specify root folder (default current)
ROOT_DIR="${1:-.}"

echo "🔍 Searching for terragrunt.hcl files under $ROOT_DIR ..."

# Find all terragrunt.hcl files and process them one by one
find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
  if grep -qE 'dependency\s+".*"\s*{' "$file" && grep -q 'mock_outputs' "$file"; then
    echo "✏️  Updating mock_outputs in $file"
    # Replace the mock_outputs line only
    sed -i.bak \
      's|^\(\s*mock_outputs\s*=\).*|\1 include.global_mocks.locals.global_mock_outputs|' \
      "$file"
  fi
done
      # 's|^\([[:space:]]*mock_outputs[[:space:]]*=\).*|\1 include.global_mock.locals.global_mock_outputs|' \

echo "✅ Done! All mock_outputs lines inside dependency blocks updated."

