#!/bin/bash

ssh-add ~/.ssh/kvm-worker3

VM_DISK="worker.qcow2"
BASE_IMAGE="ubuntu-base.qcow2"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
CLOUD_INIT_YAML="cloud-init-worker.yaml"


# === Ensure base image exists ===
if [ ! -f "$BASE_IMAGE" ]; then
    echo "⬇️  Downloading base Ubuntu cloud image..."
    wget "$IMAGE_URL" -O "$BASE_IMAGE"
else
    echo "✅ Base image already exists: $BASE_IMAGE"
fi

# === Create VM disk from base image ===
echo "💽 Creating VM disk for k8s-worker..."
qemu-img create -f qcow2 -F qcow2 -b $BASE_IMAGE ./worker.qcow2 20G

# === Verify cloud-init file exists ===
if [ ! -f "$CLOUD_INIT_YAML" ]; then
    echo "❌ Missing cloud-init file: $CLOUD_INIT_YAML"
    exit 1
fi

# === Launch VM ===
echo "🚀 Launching VM k8s-worker..."
virt-install --name k8s-worker --memory 4096 --vcpus 4 --disk path=./worker.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network bridge=br0 --network network=default --cloud-init user-data=cloud-init-worker.yaml --noautoconsole

echo "✅ VM k8s-worker launched successfully"
