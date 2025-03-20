#!/bin/bash

MASTER_IP=$(virsh net-dhcp-leases default | grep k8s-node-master | awk '{print $5}' | cut -d'/' -f1)

if [[ -n "$MASTER_IP" ]]; then
    echo "✅ Master Node IP: $MASTER_IP"
else
    echo "❌ Error: Master Node IP not found!"
fi

WORKER_IPS=$(virsh net-dhcp-leases default | grep k8s-node-worker | awk '{print $5}' | cut -d'/' -f1)
echo "Worker Node IPs: $WORKER_IPS"
