#!/bin/bash

# Get master IP
MASTER_IP=$(virsh net-dhcp-leases default | grep k8s-node-master | awk '{print $5}' | cut -d'/' -f1)

if [[ -n "$MASTER_IP" ]]; then
    echo "✅ Master Node IP: $MASTER_IP"
else
    echo "❌ Error: Master Node IP not found!"
fi

# Get all worker IPs into an array
readarray -t WORKER_IPS < <(virsh net-dhcp-leases default | grep k8s-node-worker | awk '{print $5}' | cut -d'/' -f1)

# Assign each worker to its own variable
WORKER1_IP=${WORKER_IPS[0]}
WORKER2_IP=${WORKER_IPS[1]}
WORKER3_IP=${WORKER_IPS[2]}

echo "🛠 Worker Node IPs:"
echo "➡️  Worker 1: $WORKER1_IP"
echo "➡️  Worker 2: $WORKER2_IP"
echo "➡️  Worker 3: $WORKER3_IP"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${MASTER_IP} "sudo cat /root/kubeadm-join.sh" \
| ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${WORKER1_IP} "sudo tee /root/kubeadm-join.sh > /dev/null && sudo chmod +x /root/kubeadm-join.sh"
echo "✅ copied kubeadm-join.sh to worker 1 ✅"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${MASTER_IP} "sudo cat /root/kubeadm-join.sh" \
| ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${WORKER2_IP} "sudo tee /root/kubeadm-join.sh > /dev/null && sudo chmod +x /root/kubeadm-join.sh"
echo "✅ copied kubeadm-join.sh to worker 2 ✅"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${MASTER_IP} "sudo cat /root/kubeadm-join.sh" \
| ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${WORKER3_IP} "sudo tee /root/kubeadm-join.sh > /dev/null && sudo chmod +x /root/kubeadm-join.sh"
echo "✅ copied kubeadm-join.sh to worker 3 ✅"

ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER1_IP} 'nohupsudo bash /root/kubeadm-join.sh > /tmp/kubeadm-join.log 2>&1 &' &
echo "joining worker 1 to the cluster"
sleep 15
echo "✅ joined worker 1 to the cluster ✅"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} 'nohup sudo bash /root/kubeadm-join.sh > /tmp/kubeadm-join.log 2>&1 &' &
echo "joining worker 2 to the cluster"
sleep 15
echo "✅ joined worker 2 to the cluster ✅"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} 'nohup sudo bash /root/kubeadm-join.sh > /tmp/kubeadm-join.log 2>&1 &' &
echo "joining worker 3 to the cluster"
sleep 15
echo "✅ joined worker 3 to the cluster ✅"

echo "🚀 Waiting for all nodes to join the cluster..."
sleep 15
echo "✅ Successfully joined all nodes to the cluster"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP}:/home/kubernetes/.kube/config ~/.kube/config
echo "✅ Successfully copied kubeconfig to local machine"
echo "🚀 Cluster is ready to use!"