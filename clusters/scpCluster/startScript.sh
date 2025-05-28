#!/bin/bash

echo "Current user: $(whoami) - startScript.sh"
id

start_time=$(date +%s)

# config values
# end for config values

ssh-add ~/.ssh/kvm-worker3
echo "added the kvm ssh public key to ssh agent"


echo "checking if base ubuntu image exists"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="../ubuntu-base.qcow2"

if [ ! -f $IMAGE_FILE ]; then
    echo "downloading the base ubuntu image"
    wget $IMAGE_URL -O $IMAGE_FILE
else
    echo "base ubuntu image already exists"
fi

qemu-img create -f qcow2 -F qcow2 -b ../ubuntu-base.qcow2 master.qcow2 20G
qemu-img create -f qcow2 -F qcow2 -b ../ubuntu-base.qcow2 worker.qcow2 20G
echo "created master and worker disk file"

echo "creating the kvm master node"
bash ./masterNode.sh

echo "creating the kvm worker node"
bash ./workerNode.sh

MASTER_IP="172.16.100.3"
WORKER_IP="172.16.100.4"


# MASTER_IP=$(virsh net-dhcp-leases default | grep k8s-node-master | awk '{print $5}' | cut -d'/' -f1)

# if [[ -n "$MASTER_IP" ]]; then
#     echo "✅ Master Node IP: $MASTER_IP"
#     echo "Dar1us2oo3" | sudo -S sed -i '/k8s-node-master/d' /etc/hosts
#     echo "${MASTER_IP} k8s-node-master" | sudo tee -a /etc/hosts > /dev/null
#     echo "added the k8s-node-master entry to the hosts file"
# else
#     echo "❌ Error: Master Node IP not found!"
# fi

# # Get all worker IPs into an array
# readarray -t WORKER_IPS < <(virsh net-dhcp-leases default | grep k8s-node-worker | awk '{print $5}' | cut -d'/' -f1)

# # Assign each worker to its own variable
# WORKER1_IP=${WORKER_IPS[0]}
# WORKER2_IP=${WORKER_IPS[1]}
# WORKER3_IP=${WORKER_IPS[2]}s

# echo "🛠 Worker Node IPs:"
# echo "➡️  Worker 1: $WORKER1_IP"
# echo "➡️  Worker 2: $WORKER2_IP"
# echo "➡️  Worker 3: $WORKER3_IP"

# we check to see if all the nodes have written finished in the /home/kubernetes/finished.txt file

while true; do
    sleep 5
    if ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "master node finished"
    else
        echo "master node not finished"
        continue
    fi
    if ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER_IP} "sudo cat /home/kubernetes/finished.txt" | grep -q "finished"; then
        echo "worker 1 finished"
    else
        echo "worker 1 not finished"
        continue
    fi

    echo "all nodes finished"
    break
done
echo "all nodes finished"

echo "!!!!!!!!!!!!!!!!!! FINISHED CREATING VPN FOR COMMUNICATION BETWEEN HOSTS !!!!!!!!!!!!!!!!!!!"

# old script

echo "copying util Files to master node"
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${MASTER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${MASTER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${MASTER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${MASTER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${MASTER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/calico.yaml kubernetes@${MASTER_IP}:/home/kubernetes

echo "copying util Files to worker node"
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubernetes.conf kubernetes@${WORKER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/containerd.conf kubernetes@${WORKER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/kubelet kubernetes@${WORKER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/daemon.json kubernetes@${WORKER_IP}:/home/kubernetes
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null utilFiles/10-kubeadm.conf kubernetes@${WORKER_IP}:/home/kubernetes

echo "copied util files to all nodes"

echo "copying script to master node"
sed "s|MASTER_IP_PLACEHOLDER|$MASTER_IP|g" scpScripts/master.sh > scpScripts/master.sh.tmp
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/master.sh.tmp kubernetes@${MASTER_IP}:/home/kubernetes/master.sh
rm scpScripts/master.sh.tmp
echo "copied script to master node"

echo "copying script to worker node"
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null scpScripts/worker.sh kubernetes@${WORKER_IP}:/home/kubernetes
echo "copied script to worker node"

echo "running script on master node"
ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo chmod +x /home/kubernetes/master.sh && /home/kubernetes/master.sh"

while true; do
    sleep 5
    if ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "master node finished configuration setup"
    else
        echo "master node not finished configuration setup"
        continue
    fi
    echo "master node finished"
    break
done

# Copy master IP file to local machine
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${MASTER_IP}:/home/kubernetes/master-ip.txt /tmp/master-ip.txt
echo "✅ Copied master IP file locally"

# update hosts file on a worker

# Copy master IP file to worker
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        /tmp/master-ip.txt kubernetes@${WORKER_IP}:/tmp/master-ip.txt

# Update hosts file on worker
ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        kubernetes@${WORKER_IP} 'sudo sh -c "echo \"$(cat /tmp/master-ip.txt) k8s-node-master\" >> /etc/hosts"'


# Clean up local master IP file
rm /tmp/master-ip.txt

scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP}:/home/kubernetes/kubeadm-join.sh ./kubeadm-join.sh
echo "copied kubeadm-join.sh to local machine"

echo "copy the kubeadm-join.sh file to the worker node"
scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubeadm-join.sh kubernetes@${WORKER_IP}:/home/kubernetes
echo "copied kubeadm-join.sh to all worker nodes"

echo "running script on worker node"
ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER_IP} "sudo chmod +x /home/kubernetes/worker.sh && /home/kubernetes/worker.sh"

echo "deleted local kubeadm join script"
rm ./kubeadm-join.sh

while true; do
    sleep 5
    if ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER_IP} "sudo cat /home/kubernetes/finishconfig.txt" | grep -q "finished node configuration"; then
        echo "worker 1 finished"
    else
        echo "worker 1 not finished"
        continue
    fi
    break
done

echo "Getting kubeconfig from master node..."
ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config

chmod 600 ~/.kube/config
echo "✅ Copied kubeconfig to local machine"

echo 'Dar1us2oo3' | sudo -S cp /etc/hosts /etc/hosts.bak

# Replace the last occurrence of 'k8s-node-master' with the provided master_ip
echo 'Dar1us2oo3' | sudo -S tac /etc/hosts | sed "0,/\(.*\)k8s-node-master/s//${MASTER_IP} k8s-node-master/" | tac | echo 'Dar1us2oo3' | sudo -S tee /etc/hosts > /dev/null

# echo "Updated /etc/hosts with master IP ${MASTER_IP}"


# kubectl get nodes
echo "### testing to see if the nodes are ready ###"
while true; do
    sleep 5
    output=$(kubectl get nodes --no-headers 2>&1)
    # If kubectl returns an error, print it and continue to retry
    if [[ $output == *"Unable to connect"* ]]; then
        echo "kubectl error: $output"
        continue
    fi
    total_nodes=$(echo "$output" | wc -l)
    ready_nodes=$(echo "$output" | awk '{print $2}' | grep -w "Ready" | wc -l)
    if [[ "$total_nodes" -gt 0 && "$total_nodes" -eq "$ready_nodes" ]]; then
        echo "✅ all nodes are ready ✅"
        echo "ready nodes: $total_nodes"
        break
    else
        echo "!!! not all nodes are ready !!! (Total: $total_nodes, Ready: $ready_nodes)"
    fi
done

echo "### all nodes are ready ###"
echo "applying calico network plugin"
kubectl apply -f calico.yaml

echo "checking all pods in kube-system namespace"
while true; do
    sleep 5
    output=$(kubectl get pods -n kube-system --no-headers 2>&1)
    if [[ $output == *"Unable to connect"* ]]; then
        echo "kubectl error: $output"
        continue
    fi
    total_pods=$(echo "$output" | wc -l)
    running_pods=$(echo "$output" | awk '{print $3}' | grep -w "Running" | wc -l)
    if [[ "$total_pods" -gt 0 && "$total_pods" -eq "$running_pods" ]]; then
        echo "✅ all pods in kube-system namespace are running ✅"
        echo "running pods: $running_pods"
        break
    else
        echo "!!! not all pods in kube-system namespace are running !!! (Total: $total_pods, Running: $running_pods)"
    fi
done


echo "finished creating the cluster ✅"
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Cluster creation finished in ${elapsed} seconds"


# echo "Running resource blocker pod"
# kubectl apply -f deployments/deployment-resource-blocker.yaml
# echo "Resource blocker pod created"