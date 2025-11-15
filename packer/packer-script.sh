#!/bin/bash
set -euo pipefail
echo "this is current directory below"
pwd

# cd ../packer/backend
cd ${packer_folder}/backend

MANIFEST="manifest.json"

# Check if manifest exists
if [[ ! -f "$MANIFEST" ]]; then
  echo "No manifest.json found – safe to run Packer for backend."
  chmod +x build_ami.sh
  ./build_ami.sh
else
  echo "manifest.json already exist for backend"
fi

cd ../frontend
# cd ${packer_folder}/frontend
if [[ ! -f "$MANIFEST" ]]; then
  echo "No manifest.json found – safe to run Packer for frontend."
  chmod +x build_ami.sh
  ./build_ami.sh
else
  echo "manifest.json already exist for frontend"

fi


# cd ../../root