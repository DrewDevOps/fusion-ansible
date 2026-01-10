#!/usr/bin/env bash
#
# create-debian12-template.sh
# Automates creation of a Debian Bookworm QCOW2 VM template on Proxmox VE
#
# Usage:
#   sudo bash create-debian12-template.sh debian-12-genericcloud-amd64.qcow2
#
# Requirements:
#   - Run as root on a Proxmox host
#   - Place your QCOW2 file in /var/lib/vz/template/qcow/
#   - Ensure you have a storage pool (e.g., local-lvm or local)

set -e

# ========================
# CONFIGURATION VARIABLES
# ========================
IMAGE_NAME=${1:-"debian-bookworm-template.qcow2"}
IMAGE_PATH="/var/lib/vz/template/qcow2/${IMAGE_NAME}"

VMID=9000
VM_NAME="debian12-template"
MEMORY=2048
CORES=2
BRIDGE="vmbr0"
STORAGE="local-lvm"   # Change to 'local' if using directory storage
CLOUD_USER="ansible"
CLOUD_PASSWORD="StrongPassw0rd"
SSH_KEY_PATH="$HOME/.ssh/id_rsa.pub"

# ========================
# CHECKS
# ========================
echo ">>> Checking prerequisites..."
if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root or with sudo."
  exit 1
fi

if [ ! -f "${IMAGE_PATH}" ]; then
  echo "QCOW2 image not found at ${IMAGE_PATH}"
  exit 1
fi

if qm status ${VMID} &>/dev/null; then
  echo "VMID ${VMID} already exists! Choose a new one or delete the old VM."
  exit 1
fi

echo ">>> Starting template creation for ${IMAGE_NAME}"

# ========================
# CREATE VM SHELL
# ========================
echo ">>> Creating VM shell..."
qm create ${VMID} \
  --name ${VM_NAME} \
  --memory ${MEMORY} \
  --cores ${CORES} \
  --net0 virtio,bridge=${BRIDGE}

# ========================
# IMPORT QCOW2 DISK
# ========================
echo ">>> Importing QCOW2 disk into storage '${STORAGE}'..."
qm importdisk ${VMID} ${IMAGE_PATH} ${STORAGE}

# ========================
# ATTACH DISK TO VM
# ========================
DISK_NAME="${STORAGE}:vm-${VMID}-disk-0"
echo ">>> Attaching imported disk..."
qm set ${VMID} --scsihw virtio-scsi-pci --scsi0 ${DISK_NAME}

# ========================
# SET BOOT DEVICE
# ========================
echo ">>> Setting boot device..."
qm set ${VMID} --boot c --bootdisk scsi0
qm set ${VMID} --serial0 socket --vga serial0

# ========================
# ADD CLOUD-INIT SUPPORT
# ========================
echo ">>> Adding cloud-init drive..."
qm set ${VMID} --ide2 ${STORAGE}:cloudinit

echo ">>> Configuring cloud-init parameters..."
qm set ${VMID} \
  --ciuser ${CLOUD_USER} \
  --cipassword ${CLOUD_PASSWORD} \
  --ipconfig0 ip=dhcp

if [ -f "${SSH_KEY_PATH}" ]; then
  qm set ${VMID} --sshkey ${SSH_KEY_PATH}
else
  echo "Warning: No SSH key found at ${SSH_KEY_PATH}, skipping SSH key injection."
fi

# ========================
# FINALIZE TEMPLATE
# ========================
echo ">>> Converting VM ${VMID} into a template..."
qm template ${VMID}

echo ">>> Template ${VM_NAME} [VMID ${VMID}] created successfully!"
echo ">>> You can now clone new VMs with:"
echo "    qm clone ${VMID} 9100 --name webserver01 --full"
echo "    qm clone ${VMID} 9101 --name dbserver01 --full"
