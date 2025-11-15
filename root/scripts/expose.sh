#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

echo "🔍 Searching for terragrunt.hcl files under $ROOT_DIR ..."

find "$ROOT_DIR" -type f -name "terragrunt.hcl" | while read -r file; do
  # Check if the file contains a global_mocks include block
  if grep -q 'include[[:space:]]*"global_mocks"' "$file"; then
    # Skip if expose = true already exists in that block
    if grep -A3 'include[[:space:]]*"global_mocks"' "$file" | grep -q 'expose[[:space:]]*='; then
      echo "⚠️  Skipping $file (already has expose = true)"
      continue
    fi

    echo "✏️  Adding expose = true to $file"

    # Insert expose = true right after the 'path =' line in the include block
    awk '
      /include[[:space:]]*"global_mocks"[[:space:]]*{/ {in_block=1}
      in_block && /path[[:space:]]*=/ {
        print $0
        print "  expose = true"
        in_block=0
        next
      }
      {print}
    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
  fi
done

echo "✅ Done! expose = true added to all global_mocks blocks that were missing it."
