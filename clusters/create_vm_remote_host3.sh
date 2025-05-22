#!/bin/bash

ssh-add ~/.ssh/kvm-worker3

# === Config ===
VM_NAME="worker3"
VM_HOSTNAME="k8s-worker3"
VM_DISK="${VM_NAME}.qcow2"
BASE_IMAGE="ubuntu-base.qcow2"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_INIT_YAML="cloud-init-${VM_NAME}.yaml"
VM_DISK_SIZE="20G"
VM_RAM="4096"
VM_CPUS="2"

# === Ensure base image exists ===
if [ ! -f "$BASE_IMAGE" ]; then
    echo "⬇️  Downloading base Ubuntu cloud image..."
    wget "$IMAGE_URL" -O "$BASE_IMAGE"
else
    echo "✅ Base image already exists: $BASE_IMAGE"
fi

# === Create VM disk from base image ===
echo "💽 Creating VM disk for $VM_NAME..."
cp "$BASE_IMAGE" "$VM_DISK"
qemu-img resize "$VM_DISK" "$VM_DISK_SIZE"

# === Verify cloud-init file exists ===
if [ ! -f "$CLOUD_INIT_YAML" ]; then
    echo "❌ Missing cloud-init file: $CLOUD_INIT_YAML"
    exit 1
fi

# === Launch VM ===
echo "🚀 Launching VM $VM_NAME..."
sudo virt-install \
  --connect qemu:///system \
  --name "$VM_HOSTNAME" \
  --memory "$VM_RAM" \
  --vcpus "$VM_CPUS" \
  --disk path="$VM_DISK",format=qcow2 \
  --os-variant ubuntu22.04 \
  --import \
  --network network=default \
  --cloud-init user-data="$CLOUD_INIT_YAML" \
  --noautoconsole


echo "✅ VM $VM_NAME launched successfully"
