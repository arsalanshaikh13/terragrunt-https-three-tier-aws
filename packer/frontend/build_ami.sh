#!/bin/bash
set -euo pipefail
# Initialize Packer plugins
echo "Initializing Packer plugins..."
packer init .


if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: Could not retrieve VPC ID or subnet ID from Terraform state"
    exit 1
fi

echo "Using VPC ID: $VPC_ID"
echo "Using Subnet ID: $SUBNET_ID"

# Get the latest Amazon Linux 2023 AMI ID 
SOURCE_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=$frontend_ami_type" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)

echo "Using latest Linux  AMI: $SOURCE_AMI"

# Create a directory for AMI IDs if it doesn't exist
# mkdir -p ../../terraform/compute/ami_ids
mkdir -p ../../modules/compute/asg/ami_ids

LOG_DIR="packer-logs"
mkdir -p "$LOG_DIR"

# Find the highest existing number
last_log=$(ls "$LOG_DIR"/*.log 2>/dev/null | sort -V | tail -n 1 || true)
if [ -z "$last_log" ]; then
    next_num=0
else
    # Extract the number from the filename
    last_num=$(basename "$last_log" .log | grep -oE '[0-9]+$' || echo 0)
    next_num=$((last_num + 1))
fi

LOG_FILE="$LOG_DIR/packerlog${next_num}.log"
echo "log file : $LOG_FILE"

# Build frontend AMI
echo "Building frontend AMI..."
PACKER_LOG=1 PACKER_LOG_PATH=$LOG_FILE packer build \
  -var "aws_region=$aws_region" \
  -var "source_ami=$SOURCE_AMI" \
  -var "vpc_id=$VPC_ID" \
  -var "ssh_username=$ssh_username" \
  -var "ssh_interface=$ssh_interface" \
  -var "frontend_instance_type=$frontend_instance_type" \
  -var "volume_type=$frontend_volume_type" \
  -var "volume_size=$frontend_volume_size" \
  -var "frontend_ami_name=$frontend_ami_name" \
  -var "subnet_id=$SUBNET_ID" \
  -var "s3_ssm_cw_instance_profile_name=$s3_ssm_cw_instance_profile_name" \
  -var "bucket_name=$bucket_name" \
  -var "internal_alb_dns_name=$internal_alb_dns_name" \
  -var "environment=$environment" \
  frontend.pkr.hcl | tee >(grep -Eo 'ami-[a-z0-9]{17}'| tail -n1 > ../../modules/compute/asg/ami_ids/frontend_ami.txt)

echo "Frontend AMI ID has been saved to ../../modules/compute/asg/ami_ids/frontend_ami.txt" 
