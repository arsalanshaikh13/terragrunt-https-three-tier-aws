#!/bin/bash
set -euo pipefail

# Validate argument
if [ $# -eq 0 ]; then
  echo "Usage: $0 <startup|cleanup>"
  exit 1
fi

operation=$1

# Determine log file name
case "$operation" in
  startup)
    file_name="startup-log"
    ;;
  cleanup)
    file_name="cleanup-log"
    ;;
  *)
    echo "Error: Invalid operation '$operation'. Use 'startup' or 'cleanup'"
    exit 1
    ;;
esac

# Set up log directory and file path
LOG_DIR="root/logs"
mkdir -p "$LOG_DIR"

# Find the highest existing numbered log file
last_file=$(find "$LOG_DIR" -maxdepth 1 -type f -name "${file_name}*.log" -printf '%f\n' 2>/dev/null | sort -V | tail -n1 || true)
# last_file=$(ls "$LOG_DIR"/startup-up*.log 2>/dev/null | sort -V | tail -n 1 || true)

if [ -z "$last_file" ]; then
  next_num=0
else
  last_num=$(basename "$last_file" .log | grep -oE '[0-9]+$' || echo 0)
  next_num=$((last_num + 1))
fi

LOG_FILE="$LOG_DIR/${file_name}${next_num}.log"
echo "Logging to: $LOG_FILE"

# Cleanup function
cleanup() {
  echo ""
  echo "Processing log file..."
  if [ -f "$LOG_FILE.tmp" ]; then
    sed -E 's/\x1b\[[0-9;]*m//g' "$LOG_FILE.tmp" > "$LOG_FILE"
    rm "$LOG_FILE.tmp"
    echo " Error Log file saved to: $LOG_FILE"
  fi
}

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

# Execute based on operation
case "$operation" in
  startup)
    {
      # chmod +x backend.sh
      ./scripts/backend.sh startup
      echo "===== Terragrunt Apply Started at $(date) ====="
      TG_PROVIDER_CACHE=1 terragrunt run --non-interactive --all -- apply --parallelism 50
      echo "===== Terragrunt Apply Finished at $(date) ====="
    } 2>&1 | tee "$LOG_FILE.tmp"
    ;;
    
  cleanup)
    ./scripts/backend.sh cleanup
    # chmod +x cleanup.sh
    ./scripts/cleanup.sh 2>&1 | tee "$LOG_FILE.tmp"
    ;;
esac

# # Capture exit code
# exit_code=$?

# # Report result
# if [ "$exit_code" -eq 0 ]; then
#   echo "✅ Operation '$operation' completed successfully"
# else
#   echo "❌ Operation '$operation' failed with exit code $exit_code"
#   exit "$exit_code"
# fi
# Capture exit code of the pipeline's leftmost command (terragrunt)
# terragrunt_rc=${PIPESTATUS[0]:-0}

# if [ "$terragrunt_rc" -ne 0 ]; then
#   echo "Terragrunt exited with code $terragrunt_rc (see $LOG_FILE for details)"
#   exit "$terragrunt_rc"
# else
#   echo "Terragrunt completed successfully — output saved to $LOG_FILE"
# fi

echo "Terragrunt completed successfully — output saved to $LOG_FILE"

# # ./startup.sh 2>&1 | tee >(sed 's/\x1b\[[0-9;]*m//g' > logs/setupnew1.log )
