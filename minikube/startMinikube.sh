#!/bin/bash

# ==== Parameters ====
CPUS=6
RAM=16384   # MB
BRIDGE_IFACE="br0"
MINIKUBE_PROFILE="custom-cluster"

# Static IP for bridge NIC
STATIC_IP="172.16.100.3"
NETMASK="29"
GATEWAY="172.16.100.1"

set -e

# ==== Start Minikube with 1 node ====
minikube start --profile=${MINIKUBE_PROFILE} \
  --driver=kvm2 \
  --nodes=1 \
  --cpus=${CPUS} \
  --memory=${RAM}

# ==== Attach persistent bridge NIC ====
VM_NAME="${MINIKUBE_PROFILE}"

echo "Stopping ${VM_NAME} for bridge NIC attach..."
minikube node stop -p ${MINIKUBE_PROFILE} ${VM_NAME}

echo "Editing ${VM_NAME} XML to add bridge NIC ($BRIDGE_IFACE)..."
TMP_XML="/tmp/${VM_NAME}.xml"
echo 'Dar1us2oo3' | sudo -S virsh dumpxml ${VM_NAME} > "$TMP_XML"

if ! grep -q "<source bridge='${BRIDGE_IFACE}'" "$TMP_XML"; then
    sed -i "/<\/devices>/i \
<interface type='bridge'>\n  <source bridge='${BRIDGE_IFACE}'/>\n  <model type='virtio'/>\n</interface>" "$TMP_XML"
    echo 'Dar1us2oo3' | sudo -S virsh define "$TMP_XML"
else
    echo "Bridge NIC already present for $VM_NAME."
fi

echo "Starting ${VM_NAME}..."
minikube node start -p ${MINIKUBE_PROFILE} ${VM_NAME}

# ==== Configure static IP for bridge NIC inside the VM (systemd-networkd) ====
echo "Configuring static bridge IP inside VM (systemd-networkd)..."

setup_vm_ip_systemd() {
  NODE_NAME=$1
  STATIC_IP=$2

  # Wait for SSH to be up
  until minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "true" 2>/dev/null; do
    echo "Waiting for SSH on $NODE_NAME..."
    sleep 2
  done

  # Wait for a NEW interface (not eth0) to appear
  echo "Waiting for new bridge NIC to appear in $NODE_NAME..."
  for i in {1..15}; do
    IFACES=$(minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "ip -o link show" | awk -F': ' '{print $2}' | grep -E 'eth|enp')
    # Exclude eth0 (primary), get the last one
    IFACE=$(echo "$IFACES" | grep -v '^eth0$' | tail -1)
    if [ -n "$IFACE" ]; then
      echo "Found bridge NIC: $IFACE"
      break
    fi
    echo "Not found yet. Retrying in 2s..."
    sleep 2
  done

  if [ -z "$IFACE" ]; then
      echo "Error: Could not determine new NIC name on $NODE_NAME!"
      minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "ip -o link show"
      return 1
  fi

  NETWORK_FILE="/etc/systemd/network/10-${IFACE}.network"

  # Write systemd-networkd file for static IP
  minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "echo '[Match]
Name=${IFACE}

[Network]
Address=${STATIC_IP}/${NETMASK}
Gateway=${GATEWAY}
' | sudo tee ${NETWORK_FILE}"

  # Restart systemd-networkd
  minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "sudo systemctl restart systemd-networkd"

  # Show network info for debugging
  minikube ssh --profile=${MINIKUBE_PROFILE} --node=${NODE_NAME} "ip addr show ${IFACE}"
}

setup_vm_ip_systemd "${MINIKUBE_PROFILE}" "${STATIC_IP}"

echo "✅ Single-node Minikube cluster ready with bridge NIC:"
echo "   Node: ${STATIC_IP} (CPUs: $CPUS, RAM: $RAM MB)"
echo "Fixing network connectivity for Minikube VM..."
minikube ssh --profile=${MINIKUBE_PROFILE} --node=${MINIKUBE_PROFILE} "sudo ip route del default via 172.16.100.1 dev eth2"
