#!/bin/bash
set -euo pipefail

# Initialize Packer plugins
echo "Initializing Packer plugins..."
packer init .


if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID" ]; then
    echo "Error: Could not retrieve VPC ID or subnet ID from Terraform state"
    exit 1
fi

if [ -z "$DB_HOST" ] || [ -z "$DB_PORT" ] || [ -z "$DB_USER" ] || [ -z "$DB_PASSWORD" ] || [ -z "$RDS_SG_ID" ]; then
    echo "Error: Could not retrieve required details from Terraform state"
    exit 1
fi

echo "Using VPC ID: $VPC_ID"
echo "Using Subnet ID: $SUBNET_ID"
echo "Using DB Host: $DB_HOST"
echo "Using DB Port: $DB_PORT"
echo "Using DB User: $DB_USER"
echo "Using RDS Security Group ID: $RDS_SG_ID"

# Create security group for Packer
echo "Creating security group for Packer..."
PACKER_SG_ID=$(aws ec2 create-security-group \
    --group-name "packer-sg-$(date +%s)" \
    --description "Security group for Packer build" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

# Add inbound rules to security group
echo "Configuring security group rules..."
aws ec2 authorize-security-group-ingress \
    --group-id "$PACKER_SG_ID" \
    --protocol tcp \
    --port 22 \
    --cidr 0.0.0.0/0

# Allow access to RDS
echo "Adding access to RDS..."
aws ec2 authorize-security-group-ingress \
    --group-id "$RDS_SG_ID" \
    --protocol tcp \
    --port 3306 \
    --source-group "$PACKER_SG_ID"

echo "Created security group: $PACKER_SG_ID"

# Get the latest Amazon Linux 2023 AMI ID
SOURCE_AMI=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=$backend_ami_type" "Name=state,Values=available" \
    --query "sort_by(Images, &CreationDate)[-1].ImageId" \
    --output text)

# Create a directory for AMI IDs if it doesn't exist
mkdir -p ../../modules/compute/asg/ami_ids

echo "Using latest Amazon Linux 2023 AMI: $SOURCE_AMI"
echo "using the bucket name $bucket_name "

cleanup() {
  
  # Guard against multiple executions
  if [[ -n "$CLEANUP_DONE" ]]; then
    return
  fi
  CLEANUP_DONE=1
  
  echo "🧹 Cleaning up temporary resources..."
  if [[ -n "$PACKER_SG_ID" ]]; then

    # Remove RDS access rule
    echo "Removing RDS access rule..."
    aws ec2 revoke-security-group-ingress \
        --group-id "$RDS_SG_ID" \
        --protocol tcp \
        --port 3306 \
        --source-group "$PACKER_SG_ID"

    # Delete security group
    echo "Cleaning up security group..."

    echo "Deleting security group $PACKER_SG_ID..."
    aws ec2 delete-security-group --group-id "$PACKER_SG_ID" || echo "Failed to delete SG or already deleted"
  fi
}
# # INCASE handle ctrl+c interrupt
# handle_interrupt() {
#   echo ""
#   echo "⚠️  Script interrupted by user"
#   exit 130
# }


# # this is always delete the security group when program exits on error or success
# # exit when script runs normally or there is any error that stops the script apart from the interrupt
# trap cleanup EXIT 
# # this will run when user presses ctrl+c and exit using exit 130
# # exit 130 will trigger trap cleanup EXIT which run cleanup and then exit the command
# trap handle_interrupt INT TERM
handle_interrupt() {
  # capture the error code the first thing in the program
  echo " error code : $?"
  local signal=$1
  echo "detecting reasons for interruption in the program"
  
  case "$signal" in
    INT)
      echo "⚠️  Script interrupted by user (Ctrl+C)"
      exit 130
      ;;
    TERM)
      echo "⚠️  Script terminated by signal"
      exit 143
      ;;
    ERR)
      echo "❌ Script failed due to error"
      exit 1
      ;;
    *)
      echo "⚠️  Script interrupted"
      exit 1
      ;;
  esac
}

# Set up traps - pass signal name to handler
# cleanup always run on error or successful completion of the script
trap cleanup EXIT 
trap 'handle_interrupt INT' INT
trap 'handle_interrupt TERM' TERM
trap 'handle_interrupt ERR' ERR


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
# Build backend AMI
echo "Building backend AMI..."
PACKER_LOG=1 PACKER_LOG_PATH=$LOG_FILE packer build \
  -var "aws_region=$aws_region" \
  -var "source_ami=$SOURCE_AMI" \
  -var "backend_instance_type=$backend_instance_type" \
  -var "ssh_username=$ssh_username" \
  -var "ssh_interface=$ssh_interface" \
  -var "vpc_id=$VPC_ID" \
  -var "subnet_id=$SUBNET_ID" \
  -var "db_host=$DB_HOST" \
  -var "db_port=$DB_PORT" \
  -var "db_user=$DB_USER" \
  -var "db_name=$DB_NAME" \
  -var "db_password=$DB_PASSWORD" \
  -var "security_group_id=$PACKER_SG_ID" \
  -var "s3_ssm_cw_instance_profile_name=$s3_ssm_cw_instance_profile_name" \
  -var "db_secret_name=$db_secret_name" \
  -var "bucket_name=$bucket_name" \
  -var "volume_type=$backend_volume_type" \
  -var "volume_size=$backend_volume_size" \
  -var "backend_ami_name=$backend_ami_name" \
  -var "environment=$environment" \
  backend.pkr.hcl | tee >(grep -Eo 'ami-[a-z0-9]{17}' | tail -n1 > ../../modules/compute/asg/ami_ids/backend_ami.txt)



# this line will only run when packer successfuly completes the program and returns exit 0
echo "Backend AMI ID has been saved to ../../modules/compute/asg/ami_ids/backend_ami.txt" 



# ## Key changes:

# 1. **Added `CLEANUP_DONE` guard** to prevent duplicate execution
# 2. **Removed `cleanup` call from `handle_interrupt()`** - let `EXIT` trap handle it
# 3. **Order of traps**: `EXIT` first, then `INT TERM` (though order doesn't technically matter)

# ## How it works:

# **Normal finish:**
# ```
# → echo runs
# → Script ends
# → EXIT trap fires
# → cleanup() runs once
# ```

# **Ctrl+C:**
# ```
# → INT trap fires
# → handle_interrupt() prints warning
# → exit 130
# → EXIT trap fires
# → cleanup() runs once
# → echo never runs (already exited)
# This pattern ensures cleanup always runs exactly once, regardless of how the script exits!RetryClaude can make mistakes. Please double-check responses.