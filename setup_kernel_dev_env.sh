#!/usr/bin/env bash
set -euo pipefail

step() {
  local message="$1"
  local border="-------------------------------------------"
  echo
  echo "$border"
  echo "- $message"
  echo "$border"
  echo
}

# vm settings - change as required
# template has only been tested with ubuntu-25.10
# only working on arm64

VM_NAME="${VM_NAME:-kernel-dev-vm}"
VM_TEMPLATE="${VM_TEMPLATE:-ubuntu-25.10}"
VM_CPUS="${VM_CPUS:-6}"
VM_MEMORY_GB="${VM_MEMORY_GB:-8}"
VM_DISK_GB="${VM_DISK_GB:-50}"

if ! command -v limactl &> /dev/null; then
    echo "limactl is not installed. Please install lima first."
    exit 1
fi 

step "Creating vm ${VM_NAME} with template ${VM_TEMPLATE} using ${VM_CPUS} CPUs, ${VM_MEMORY_GB}GB memory and ${VM_DISK_GB}GB disk"

if limactl list | grep -q "${VM_NAME}"; then
    echo "VM ${VM_NAME} already exists. Exiting as the script is not idempotent."
    exit 1
else
    echo "Creating VM ${VM_NAME}..."
    limactl create                \
        --cpus   ${VM_CPUS}       \
        --memory ${VM_MEMORY_GB}  \
        --disk   ${VM_DISK_GB}    \
        --name   ${VM_NAME}       \
        --yes                     \
        template://${VM_TEMPLATE}
fi

step "starting vm ${VM_NAME}"
limactl start "${VM_NAME}"

step "Setting up ${VM_NAME} for linux kernel development"

# vscode launch.json
limactl copy ./conf/launch.json "${VM_NAME}:~/"
limactl shell ${VM_NAME} < ./installation_steps.sh | tee ${VM_NAME}.log

step "Setup complete."

step "To view the setup logs, check ${VM_NAME}.log"


