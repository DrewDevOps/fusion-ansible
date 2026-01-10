VMID=9000
IMG_PATH=/var/lib/vz/template/qcow/debian-12-genericcloud-amd64.qcow2
STORAGE=local-lvm

# Remove any old VM
qm destroy $VMID --purge 2>/dev/null || true

# Create a fresh VM
qm create $VMID --name debian-bookworm --memory 2048 --cores 2 --net0 virtio,bridge=vmbr0

# Import the disk
qm importdisk $VMID $IMG_PATH $STORAGE

# Attach it as SCSI disk
qm set $VMID --scsihw virtio-scsi-pci --scsi0 ${STORAGE}:vm-${VMID}-disk-0

# Add cloud-init drive
qm set $VMID --ide2 ${STORAGE}:cloudinit

# Set boot device and serial console
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0

# Configure cloud-init
qm set $VMID --ciuser debian
qm set $VMID --cipassword 'Debian@123'
qm set $VMID --ipconfig0 ip=dhcp
qm set $VMID --nameserver 8.8.8.8
qm set $VMID --sshkeys ~/.ssh/id_rsa.pub


# Then regenerate the cloud-init ISO
qm cloudinit update $VMID
