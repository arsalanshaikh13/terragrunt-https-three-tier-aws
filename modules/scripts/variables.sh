#!/bin/bash 

# set -euo pipefail

# # Check required arguments
# if [[ $# -lt 1 ]]; then
#   echo "Usage: $0 <folder> <type>"
#   echo "Example: $0 myfolder string"
#   exit 1
# fi

# cd $1

# # use the 2nd argument and if 2nd argument is not provided then default to string
# # var_type=$2 || "string"
# var_type="${2:-string}"



# MAIN_FILE="main.tf"
# VARS_FILE="variables.tf"


# # Extract all variable names used as var.something
# # grep -v consider  the lines that don't have '#' in them i.e. commented out lines
# grep -v '^[[:space:]]*#' "$MAIN_FILE" \
#   | grep -o 'var\.[A-Za-z0-9_]\+' \
#   | sed 's/var\.//' \
#   | awk '!seen[$0]++' \
#   | while read -r varname; do
#       echo "variable \"$varname\" {" >> "$VARS_FILE"
#       echo "  type        = $var_type" >> "$VARS_FILE"
#       echo "  description = \"$varname variable\"" >> "$VARS_FILE"
#       echo "}" >> "$VARS_FILE"
#       echo "" >> "$VARS_FILE"
#     done

# # using "| awk '!seen[$0]++' \" instead of   "| sort -u \""
# echo "✅ Variables appended to $VARS_FILE"


#!/usr/bin/env bash
set -euo pipefail

# if [[ $# -lt 1 ]]; then
#   echo "Usage: $0 <type>"
#   echo "Example: $0 string"
#   echo "Example: $0 number"
#   exit 1
# fi

# variable type (string, number, bool, list, etc.)
var_type="${1:-string}"

echo "🔍 Searching for all main.tf files..."

find . -type f -name "main.tf" -not -path "*/.terragrunt-cache/*" | while read -r file; do
    dir=$(dirname "$file")
    echo "📁 Processing module: $dir"

    cd "$dir"

    MAIN_FILE="main.tf"
    VARS_FILE="variables.tf"

    # Create variables.tf if not exists
    if [[ ! -f "$VARS_FILE" ]]; then
      touch "$VARS_FILE"
    fi

    # Extract variables, ignoring commented lines
    grep -v '^[[:space:]]*#' "$MAIN_FILE" \
      | grep -o 'var\.[A-Za-z0-9_]\+' \
      | sed 's/var\.//' \
      | awk '!seen[$0]++' \
      | while read -r varname; do

          # Skip if variables.tf already has this variable
          if grep -q "variable \"$varname\"" "$VARS_FILE"; then
            continue
          fi

          echo "🔧 Adding variable: $varname"

          {
            echo "variable \"$varname\" {"
            echo "  type        = $var_type"
            echo "  description = \"$varname variable\""
            echo "}"
            echo ""
          } >> "$VARS_FILE"
        done

    echo "✅ Updated $VARS_FILE in $dir"
    cd - >/dev/null

done

echo "🎉 Completed variable generation for all modules."
