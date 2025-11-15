#!/usr/bin/env bash
set -euo pipefail

# Optional: specify root folder (default current)
ROOT_DIR="${1:-.}"
OUTPUT_FILE="$ROOT_DIR/global-mocks.hcl"

echo "🔍 Searching for terragrunt.hcl files under $ROOT_DIR ..."

# Find all occurrences of 'outputs.<word>' in all terragrunt.hcl files
# Extract only the word after 'outputs.'
output_vars=$(grep -rho 'outputs\.[A-Za-z0-9_]\+' "$ROOT_DIR" --include="terragrunt.hcl" \
  | sed 's/outputs\.//' \
  | sort -u)

if [ -z "$output_vars" ]; then
  echo "⚠️  No outputs.* references found in terragrunt.hcl files."
  exit 0
fi

# Create global-mocks.hcl
{
  echo "locals {"
  echo "  global-mocks = {"
  echo
  for var in $output_vars; do
    echo "    $var = \"\""
  done
  echo
  echo "  }"
  echo "}"
} > "$OUTPUT_FILE"

echo "✅ Generated $OUTPUT_FILE with $(echo "$output_vars" | wc -l) entries."
