#!/bin/bash

ssh-add ~/.ssh/kvm-cloudinit-key
echo "added the kvm ssh public key to ssh agent"


echo "checking if base ubuntu image exists"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="ubuntu-base.qcow2"
if [ ! -f $IMAGE_FILE ]; then
    echo "downloading the base ubuntu image"
    wget $IMAGE_URL -O $IMAGE_FILE
else
    echo "base ubuntu image already exists"
fi


cp ubuntu-base.qcow2 master.qcow2
qemu-img resize master.qcow2 20G
echo "make master disk file"
cp ubuntu-base.qcow2 worker1.qcow2
qemu-img resize worker1.qcow2 20G
echo "make worker1 disk files"
cp ubuntu-base.qcow2 worker2.qcow2
qemu-img resize worker2.qcow2 20G
echo "make worker2 disk files"
cp ubuntu-base.qcow2 worker3.qcow2
qemu-img resize worker3.qcow2 20G
echo "make worker3 disk files"



echo "destroying the default network"
virsh net-destroy default
echo "starting the default network"
virsh net-start default
echo "deleting the old leases"
echo "Dar1us2oo3" | sudo -S rm -f /var/lib/libvirt/dnsmasq/default.leases
echo "restarting the libvirtd service"
echo "Dar1us2oo3" | sudo -S systemctl restart libvirtd
echo "successfully restarted the libvirtd service"


echo "creating the kvm master node"
bash ./masterNode.sh
echo "creating the kvm worker nodes"
bash ./workerNodes.sh
echo "created the kvms"

echo "running the starting scripts in the vm's"
sleep 30

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

# we check to see if all the nodes have written finished in the /home/kubernetes/finished.txt file

while true; do
    sleep 5
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "master node finished"
    else
        echo "master node not finished"
        continue
    fi
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER1_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "worker 1 finished"
    else
        echo "worker 1 not finished"
        continue
    fi
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "worker 2 finished"
    else
        echo "worker 2 not finished"
        continue
    fi
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "worker 3 finished"
    else
        echo "worker 3 not finished"
        continue
    fi
    echo "all nodes finished"
    break
done
echo "all nodes finished"

echo "copying util Files to master node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${MASTER_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${MASTER_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${MASTER_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${MASTER_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${MASTER_IP}:/home/kubernetes

echo "copying util Files to worker1 node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${WORKER1_IP}:/home/kubernetes

echo "copying util Files to worker2 node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${WORKER2_IP}:/home/kubernetes

echo "copying util Files to worker3 node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${WORKER3_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${WORKER3_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${WORKER3_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${WORKER3_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${WORKER3_IP}:/home/kubernetes
echo "copied util files to all nodes"

echo "copying script to master node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/master.sh kubernetes@${MASTER_IP}:/home/kubernetes
echo "copied script to master node"

echo "copying script to worker nodes"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/worker.sh kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/worker.sh kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/worker.sh kubernetes@${WORKER3_IP}:/home/kubernetes
echo "copied script to worker nodes"

echo "running script on master node"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo chmod +x /home/kubernetes/master.sh && /home/kubernetes/master.sh"

while true; do
    sleep 5
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "master node finished configuration setup"
    else
        echo "master node not finished configuration setup"
        continue
    fi
    echo "master node finished"
    break
done

scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP}:/home/kubernetes/kubeadm-join.sh ./kubeadm-join.sh
echo "copied kubeadm-join.sh to local machine"
echo "copy the kubeadm-join.sh file to the worker nodes"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubeadm-join.sh kubernetes@${WORKER1_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubeadm-join.sh kubernetes@${WORKER2_IP}:/home/kubernetes
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubeadm-join.sh kubernetes@${WORKER3_IP}:/home/kubernetes
echo "copied kubeadm-join.sh to all worker nodes"
echo "running script on worker nodes"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER1_IP} "sudo chmod +x /home/kubernetes/worker.sh && /home/kubernetes/worker.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} "sudo chmod +x /home/kubernetes/worker.sh && /home/kubernetes/worker.sh"
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} "sudo chmod +x /home/kubernetes/worker.sh && /home/kubernetes/worker.sh"

while true; do
    sleep 5
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER1_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "worker 1 finished"
    else
        echo "worker 1 not finished"
        continue
    fi
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "worker 2 finished"
    else
        echo "worker 2 not finished"
        continue
    fi
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "worker 3 finished"
    else
        echo "worker 3 not finished"
        continue
    fi
    echo "all worker nodes finished configuration setup"
    break
done



# echo "10%"
# sleep 35
# echo "25%"
# sleep 35
# echo "40%"
# sleep 35
# echo "50%"
# sleep 35
# echo "60%"
# sleep 35
# echo "75%"
# sleep 35
# echo "90%"
# sleep 35
# echo "100%"
echo "finished running the starting scripts in the vm's"