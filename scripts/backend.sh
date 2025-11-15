#!/bin/bash

set -euo pipefail
operation=${1:-startup}  # Default to startup if no arg

CACHE_DIR="backend-tfstate-bootstrap/.terragrunt-cache"

echo "Checking backend infrastructure... inside: $CACHE_DIR"
      
# Look for terraform.tfstate in backend directory
BACKEND_STATE=$(find backend-tfstate-bootstrap/.terragrunt-cache -type f -name "terraform.tfstate" 2>/dev/null | head -n1)
echo "$BACKEND_STATE"
if [ -z "$BACKEND_STATE" ]; then
  if [ "$operation" = "cleanup" ]; then
    echo "❌ Error: Backend infrastructure does not exist. Cannot perform cleanup."
    exit 1
  fi
  echo "❌ Backend state file not found. Running backend setup..."
  TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50

# elif ! grep -qE '"arn:aws:[^"]+"|"id":\s*"[^"]+"' "$BACKEND_STATE"; then
elif  grep -q '"resources": \[\]' "$BACKEND_STATE"; then

  if [ "$operation" = "cleanup" ]; then
    echo "❌ Error: Backend infrastructure does not exist. Cannot perform cleanup."
    exit 1
  fi
  echo "⚠️  Backend state file exists but appears empty. Running backend setup..."
  TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50

else
  echo "✅ Backend infrastructure exists (resources is not empty)"
  exit 0
fi


# # If cache folder does NOT exist → run apply immediately
# if [[ ! -d "$CACHE_DIR" ]]; then
#   echo "⚠️  Cache directory does not exist."
#   echo "🛠  Running Terragrunt apply to initialize backend..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
#   exit 0
# fi

# # Find terraform.tfstate inside nested terragrunt-cache directories
# STATE_FILE=$(find "$CACHE_DIR" -type f -name "terraform.tfstate" | head -n 1)

# if [[ -z "$STATE_FILE" ]]; then
#   echo "⚠️  No terraform.tfstate found inside cache!"
#   echo "🛠  Running Terragrunt apply..."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
#   exit 0
# fi

# echo "📄 Found terraform.tfstate: $STATE_FILE"
# echo "Checking its contents..."

# # Check if resources array is empty
# if grep -q '"resources": \[\]' "$STATE_FILE"; then
#   echo "🚨 State file contains NO resources. Need to create backend."
#   TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --working-dir backend-tfstate-bootstrap -- apply --parallelism 50
# else
#   echo "✅ State file contains resources. Backend already initialized."
# fi

