#!/usr/bin/env bash
set -euo pipefail

# Optional: specify root folder (default current)
ROOT_DIR="${1:-.}"

echo "🔍 Searching for output.tf files under $ROOT_DIR ..."

# Find all output.tf files recursively
find "$ROOT_DIR" -type f -name "output.tf" | while read -r output_file; do
  dir=$(dirname "$output_file")
  new_file="$dir/outputs.tf"

  # Check if outputs.tf already exists
  if [ -f "$new_file" ]; then
    echo "⚠️  Skipping $dir (already contains outputs.tf)"
    continue
  fi

  echo "✏️  Renaming: $output_file → $new_file"
  mv "$output_file" "$new_file"
done

echo "✅ Done! All output.tf files renamed to outputs.tf (where applicable)."
