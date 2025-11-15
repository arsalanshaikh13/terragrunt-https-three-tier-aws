#!/bin/bash
set -euo pipefail
echo "Cleaning up AMIs"

export AWS_REGION="$region"
declare -A AMI_FILES=(
  # ["frontend"]="${frontend_ami_file}/modules/asg/ami_ids/frontend_ami.txt"
  ["frontend"]="${frontend_ami_file}"
  ["backend"]="${backend_ami_file}"
)

echo "frontend and backend ami file : $frontend_ami_file &&& $backend_ami_file";

  # ["frontend"]="terraform/compute/modules/asg/ami_ids/frontend_ami.txt"
  # ["frontend"]="/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/asg/ami_ids/frontend_ami.txt"
  # # ["backend"]="terraform/compute/modules/asg/ami_ids/backend_ami.txt"
  # ["backend"]="/mnt/c/Users/DELL/ArsVSCode/CS50p_project/project_aFinal/website/${web}/animations/scroll/aws_three_tier_arch/lirw-three-tier/folder-based-project/terraform/compute/modules/asg/ami_ids/backend_ami.txt"
  # ["backend"]="terraform/compute/modules/asg/ami_ids/backend_ami.txt"

# Loop over frontend and backend AMIs
for component in frontend backend; do
  AMI_FILE="${AMI_FILES[$component]}"
  AMI_ID=""

  # Load AMI ID if file exists
  if [ -f "$AMI_FILE" ]; then
    AMI_ID=$(cat "$AMI_FILE")
  fi

  if [ -n "$AMI_ID" ]; then
    echo "🚀 Deregistering ${component^} AMI: $AMI_ID"

    echo "🔍 Finding and deleting associated snapshots..."
    snapshot_ids=$(aws ec2 describe-images \
      --image-ids "$AMI_ID" \
      --region "$AWS_REGION" \
      --query "Images[0].BlockDeviceMappings[].Ebs.SnapshotId" \
      --output text 2>/dev/null)

    aws ec2 deregister-image --image-id "$AMI_ID" --region "$AWS_REGION"

    if [ -n "$snapshot_ids" ]; then
      for snap_id in $snapshot_ids; do
        if [ -n "$snap_id" ]; then
          echo "🗑️  Deleting snapshot: $snap_id"
          aws ec2 delete-snapshot --snapshot-id "$snap_id" --region "$AWS_REGION" || true
        fi
      done
    fi
  else
    echo "⚠️  No ${component^} AMI ID found, skipping deregistration"
  fi
done
