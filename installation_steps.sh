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



step "Installing linux kernel build dependencies"
sudo apt update &&
sudo apt install -y build-essential libncurses-dev bison flex libssl-dev libelf-dev bc git

step "Install gdb and bpftool for debugging "

sudo apt update &&
sudo apt install -y gdb &&
curl -fLJ "https://github.com/Netflix/bpftop/releases/latest/download/bpftop-$(uname -p)-unknown-linux-gnu" -o /tmp/bpftop \
    && chmod +x /tmp/bpftop \
    && sudo mv /tmp/bpftop /usr/local/sbin


step "Creating ~/dev folder"
mkdir ~/dev

# sources for the current kernel versions - change as appropriate
export kernel_version=$(echo "v$(uname -r | cut -d- -f1 | cut -d. -f1,2)")

step "Cloning kernel version: $kernel_version"
git clone \
    --branch $kernel_version \
    --depth 1 https://github.com/torvalds/linux ~/dev/linux
cd ~/dev/linux

step "Installing system dependencies"
sudo apt install -y python3-pip flake8 pylint cargo rustc qemu-system-aarch64

step "Installing virtme-ng" 

( git clone https://github.com/arighi/virtme-ng ~/dev/virtme-ng && cd ~/dev/virtme-ng && git checkout 094ddac ) || {
    echo "Failed to clone virtme-ng repository."
    exit 1
}


step "Installing vng python dependencies"
cd ~/dev/virtme-ng
BUILD_VIRTME_NG_INIT=1 pip3 install . --break-system-packages
 
step "Creating a vng alias"
echo "alias vng='~/dev/virtme-ng/vng'" >> ~/.bashrc
source ~/.bashrc
cd ~
~/dev/virtme-ng/vng --version

step "Installing Clang for kernel compilation"
curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
sudo install -o root -g root -m 644 microsoft.gpg /usr/share/keyrings/microsoft-archive-keyring.gpg && \
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/vscode stable main" > /etc/apt/sources.list.d/vscode.list' && \
sudo apt update && \
sudo apt install -y code gdb-multiarch ccache clang clangd llvm lld \
                 libguestfs-tools libssl-dev trace-cmd python3-pip jsonnet \
                 libelf-dev bison bindfs mmdebstrap proot systemtap flex yacc bc debian-archive-keyring

step "Installing https://github.com/FlorentRevest/linux-kernel-vscode"

cd ~/dev/linux
git clone https://github.com/FlorentRevest/linux-kernel-vscode .vscode/

# use arm64
sed -i 's/^.*TARGET_ARCH=arm64/TARGET_ARCH=arm64/' .vscode/local.sh

.vscode/tasks.sh update  # Needs to be run once to generate settings.json

step "copy vscode launch.json"
cp ~/launch.json .vscode/launch.json

# remove any previous config
rm -f .config

step "compiling the kernel - this may take a while"
# in case you are using ghossty
export TERM=xterm-256color

cd ~/dev/linux
.vscode/tasks.sh build  # build the kernel
