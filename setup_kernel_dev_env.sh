#!/usr/bin/env bash

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
# template has only been tested with ubuntu-24.10
# only working on arm64

VM_NAME="${VM_NAME:-kernel-dev-vm}"
VM_TEMPLATE="${VM_TEMPLATE:-ubuntu-24.10}"
VM_CPUS="${VM_CPUS:-6}"
VM_MEMORY_GB="${VM_MEMORY_GB:-8}"
VM_DISK_GB="${VM_DISK_GB:-50}"

if ! command -v limactl &> /dev/null; then
    echo "limactl is not installed. Please install lima first."
    exit 1
fi 

step "Creating vm ${VM_NAME} with template ${VM_TEMPLATE} using ${VM_CPUS} CPUs, ${VM_MEMORY_GB}GB memory and ${VM_DISK_GB}GB disk"

if limactl list | grep -q "${VM_NAME}"; then
    echo "VM ${VM_NAME} already exists. Skipping creation step."
else
    echo "Creating VM ${VM_NAME}..."
    limactl create                    \
        --cpus   ${VM_CPUS}       \
        --memory ${VM_MEMORY_GB}  \
        --disk   ${VM_DISK_GB}    \
        --name   ${VM_NAME}       \
        --yes                     \
        template://${VM_TEMPLATE}
fi

step "starting vm ${VM_NAME}"
limactl start ${VM_NAME}

step "Setting up ${VM_NAME} for linux kernel development"
limactl shell ${VM_NAME} < ./installation_steps.sh | tee ${VM_NAME}.log

step "Setup complete."

step "Next steps:"

echo "You can now connect to the VM using:"
echo "limactl shell ${VM_NAME}" 
echo ""

echo "To connect from VisualStudio Code, use the Remote - SSH extension and connect to:"
limactl show-ssh ${VM_NAME}

step "To view the setup log, check ${VM_NAME}.log"


