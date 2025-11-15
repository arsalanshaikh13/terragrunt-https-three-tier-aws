#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="${1:-.}"

REPLACEMENT='        echo "exit code : $exit_code"
        exit $exit_code'

echo "🔍 Updating tflint before_hook blocks under $ROOT_DIR ..."

find "$ROOT_DIR" -type f -name "terragrunt.hcl" \
    -not -path "*/.terragrunt-cache/*" | while read -r file; do
    
    # Check if this file even contains the tflint hook
    if ! grep -q 'before_hook[[:space:]]*"tflint"' "$file"; then
        continue
    fi
    
    echo "✏️  Patching $file"

    awk -v replacement="$REPLACEMENT" '
        BEGIN {
            in_hook = 0
            skip_block = 0
        }

        # Detect start of before_hook "tflint"
        /before_hook[[:space:]]*"tflint"/ {
            in_hook = 1
        }

        # When inside tflint hook, detect the IF block start
        in_hook && /^\s*if\s*\[\s*\$exit_code/ {
            skip_block = 1
            next
        }

        # Skip all lines until the closing "fi"
        skip_block {
            if ($0 ~ /^\s*fi\s*$/) {
                skip_block = 0
                print replacement
                next
            }
            next
        }

        # Normal printing
        { print }

    ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

done

echo "✅ Completed updating all TFLint before_hook blocks."


### Reverse operation, putting back the original block

# set -euo pipefail

# ROOT_DIR="${1:-.}"

# ORIGINAL_BLOCK='        if [ $exit_code -gt 0 ]; then
#           echo "exit code : $exit_code"
#           echo "✅ TFLint completed with issues (non-fatal). Continuing Terragrunt..."
#           exit 0
#         else
#           echo "exit code : $exit_code"
#           exit $exit_code
#         fi'

# echo "🔍 Restoring original tflint before_hook blocks in $ROOT_DIR..."

# find "$ROOT_DIR" -type f -name "terragrunt.hcl" \
#     -not -path "*/.terragrunt-cache/*" | while read -r file; do

#     # Only files containing the short version should be restored
#     if ! grep -q 'echo "exit code : \$exit_code"' "$file"; then
#         continue
#     fi

#     # Skip files already containing the original long form
#     if grep -q 'TFLint completed with issues' "$file"; then
#         continue
#     fi

#     echo "✏️  Restoring in $file"

#     awk -v original="$ORIGINAL_BLOCK" '
#         BEGIN {
#             in_hook = 0
#             replace_mode = 0
#         }

#         # Detect beginning of before_hook "tflint"
#         /before_hook[[:space:]]*"tflint"/ {
#             in_hook = 1
#         }

#         # Inside tflint hook, detect the simple two-line block
#         in_hook && /^\s*echo\s+"exit code : \$exit_code"/ {
#             replace_mode = 1   # start replacing
#             next
#         }

#         replace_mode && /^\s*exit\s+\$exit_code/ {
#             # Replace the simple block with original block
#             print original
#             replace_mode = 0
#             next
#         }

#         # Stop hook scanning after EOT or }
#         in_hook && /^[[:space:]]*EOT/ { in_hook = 0 }
#         in_hook && /^[[:space:]]*}/ { in_hook = 0 }

#         { print }

#     ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"

# done

# echo "✅ Restoration completed!"
