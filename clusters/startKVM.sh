#!/bin/bash

generate_wg_config() {
  local node_name=$1
  local private_key_file=$2
  local wg_ip=$3
  local listen_port=$4

  # Peer 1
  local peer1_public_key=$5
  local peer1_allowed_ip=$6
  local peer1_endpoint=$7

  # Peer 2
  local peer2_public_key=$8
  local peer2_allowed_ip=$9
  local peer2_endpoint=${10}

  # Peer 3
  local peer3_public_key=${11}
  local peer3_allowed_ip=${12}
  local peer3_endpoint=${13}

  # Peer 4
  local peer4_public_key=${14}
  local peer4_allowed_ip=${15}
  local peer4_endpoint=${16}

  # Peer 5
  local peer5_public_key=${17}
  local peer5_allowed_ip=${18}
  local peer5_endpoint=${19}

  # Peer 6
  local peer6_public_key=${20}
  local peer6_allowed_ip=${21}
  local peer6_endpoint=${22}

  local output_file="wgconfs/${node_name}.conf"
  mkdir -p wgconfs

  echo "[Interface]" > "$output_file"
  echo "PrivateKey = $(< "$private_key_file")" >> "$output_file"
  echo "Address = $wg_ip/24" >> "$output_file"
  echo "ListenPort = $listen_port" >> "$output_file"
  echo "" >> "$output_file"

  for i in {1..6}; do
    eval pub_key=\$peer${i}_public_key
    eval allowed_ip=\$peer${i}_allowed_ip
    eval endpoint=\$peer${i}_endpoint

    echo "[Peer]" >> "$output_file"
    echo "PublicKey = $pub_key" >> "$output_file"
    echo "AllowedIPs = $allowed_ip/32" >> "$output_file"
    echo "Endpoint = $endpoint" >> "$output_file"
    echo "PersistentKeepalive = 25" >> "$output_file"
    echo "" >> "$output_file"
  done

  echo "✅ Generated WireGuard config for $node_name"

} 

start_time=$(date +%s)

# config values

declare -A HOST_LAN_IP=(
    [host1]=192.168.1.136
    [host2]=192.168.1.144
    [host3]=192.168.1.145
)

declare -A HOST_WG_IP=(
    [host1]=10.10.0.1
    [host2]=10.10.0.2
    [host3]=10.10.0.3
)

declare -A VM_WG_IP=(
    [master]=10.10.0.10
    [worker1]=10.10.0.11
    [worker2]=10.10.0.12
    [worker3]=10.10.0.13
)

# end for config values

ssh-add ~/.ssh/kvm-cloudinit-key
echo "added the kvm ssh public key to ssh agent"

echo "Runinng the script with these remote hosts"
HOST_2="darius@${HOST_LAN_IP[host2]}"
HOST_3="darius@${HOST_LAN_IP[host3]}"
echo "!!!!!!!!!!!!! HOST_2: $HOST_2 !!!!!!!!!!!!!"
echo "!!!!!!!!!!!!! HOST_3: $HOST_3 !!!!!!!!!!!!!"

echo "checking if base ubuntu image exists"
IMAGE_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
IMAGE_FILE="ubuntu-base.qcow2"

if [ ! -f $IMAGE_FILE ]; then
    echo "downloading the base ubuntu image"
    wget $IMAGE_URL -O $IMAGE_FILE
else
    echo "base ubuntu image already exists"
fi

mkdir -p wgpubs wgconfs wireguard-keys

for name in master worker1; do
    cp $IMAGE_FILE "${name}.qcow2"
    qemu-img resize "${name}.qcow2" 20G
    echo "created ${name} disk file"
done

echo "creating the kvm master node"
bash ./masterNode.sh
echo "creating the kvm worker nodes"
bash ./workerNodeHost1.sh
echo "created the k vms for host 1"

echo "copying the starting files to the remote host 2"
sshpass -p 'Dar1us2oo3' scp create_vm_remote_host2.sh "$HOST_2":~/create_vm_remote_host2.sh
sshpass -p 'Dar1us2oo3' scp cloud-init-worker2.yaml "$HOST_2":~/cloud-init-worker2.yaml
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sudo -S bash ~/create_vm_remote_host2.sh && rm ~/create_vm_remote_host2.sh ~/cloud-init-worker2.yaml"

echo "copying the disk files to the remote host 3"
sshpass -p 'Dar1us2oo3' scp create_vm_remote_host3.sh "$HOST_3":~/create_vm_remote_host3.sh
sshpass -p 'Dar1us2oo3' scp cloud-init-worker3.yaml "$HOST_3":~/cloud-init-worker3.yaml
sshpass -p 'Dar1us2oo3' ssh "$HOST_3" "echo 'Dar1us2oo3' | sudo -S bash ~/create_vm_remote_host3.sh && rm ~/create_vm_remote_host3.sh ~/cloud-init-worker3.yaml"

echo "waiting for DHCP leases to be assigned"
sleep 30

MASTER_IP=$(virsh net-dhcp-leases default | grep k8s-node-master | awk '{print $5}' | cut -d/ -f1)
WORKER1_IP=$(virsh net-dhcp-leases default | grep k8s-node-worker1 | awk '{print $5}' | cut -d/ -f1)

read WORKER2_IP < <(sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no $HOST_2 "echo 'Dar1us2oo3' | sudo -S virsh net-dhcp-leases default | grep k8s-node-worker2 | awk '{print \$5}' | cut -d/ -f1")
read WORKER3_IP < <(sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no $HOST_3 "echo 'Dar1us2oo3' | sudo -S virsh net-dhcp-leases default | grep k8s-node-worker3 | awk '{print \$5}' | cut -d/ -f1")


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

    host2_status=$(sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_2 "ssh -i ~/.ssh/kvm-worker2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} 'sudo cat /home/kubernetes/finished.txt'")
    if echo "$host2_status" | grep -q "finished"; then
        echo "worker 2 finished"
    else
        echo "worker 2 not finished"
        continue
    fi

    host3_status=$(sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_3 "ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} 'sudo cat /home/kubernetes/finished.txt'")
    if echo "$host3_status" | grep -q "finished"; then
        echo "worker 3 finished"
    else
        echo "worker 3 not finished"
        continue
    fi
    echo "all nodes finished"
    break
done
echo "all nodes finished"

echo "getting wg.pub from each vm"

#get wg.pub from master node
echo "getting wg.pub from master node"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP}:/home/kubernetes/wg.pub ./wgpubs/master.pub
echo "got wg.pub from master node"
echo
echo

echo "getting wg.pub from worker1 node"
# get wg.pub from worker1 node
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER1_IP}:/home/kubernetes/wg.pub ./wgpubs/worker1.pub
echo "got wg.pub from worker1 node"
echo
echo

echo "getting wg.pub from host2 and worker2 node"
# copy wg.pub from worker2 node to host 2 and from host 2 to local machine
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_2 "scp -i ~/.ssh/kvm-worker2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP}:/home/kubernetes/wg.pub ./wgpubs/worker2.pub"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_2:~/wgpubs/worker2.pub ./wgpubs/worker2.pub
echo "got wg.pub from host2 and worker2 node"
echo
echo

echo "getting wg.pub from host3 and worker3 node"
# copy wg.pub from worker3 node to host 3 and from host 3 to local machine
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_3 "scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP}:/home/kubernetes/wg.pub ./wgpubs/worker3.pub"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_3:~/wgpubs/worker3.pub ./wgpubs/worker3.pub
echo "got wg.pub from host3 and worker3 node"
echo
echo

# copy wg.pub from host 2 to host 1
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_2:~/wireguard-keys/host-2.pub ./wgpubs/host2.pub

# copy wg.pub from host 3 to host 1
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $HOST_3:~/wireguard-keys/host-3.pub ./wgpubs/host3.pub

cp ~/wireguard-keys/host-1.pub ./wgpubs/host1.pub
echo "copied wg.pub from all nodes"

# generating the wireguard config files for each machine or vm

generate_wg_config "master" \
    "/etc/wireguard/private.key" \
    "${VM_WG_IP[master]}" \
    51820 \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820"

generate_wg_config "worker1" \
    "/etc/wireguard/private.key" \
    "${VM_WG_IP[worker1]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820"

generate_wg_config "worker2" \
    "/etc/wireguard/private.key" \
    "${VM_WG_IP[worker2]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820"

generate_wg_config "worker3" \
    "/etc/wireguard/private.key" \
    "${VM_WG_IP[worker3]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820"

generate_wg_config "host-1" \
    "~/wireguard-keys/host-1.key" \
    "${HOST_WG_IP[host1]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820"

generate_wg_config "host-2" \
    "~/wireguard-keys/host-2.key" \
    "${HOST_WG_IP[host2]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820" \
    "$(cat ./wgpubs/host3.pub)" \
    "${HOST_WG_IP[host3]}" \
    "${HOST_LAN_IP[host3]}:51820"

generate_wg_config "host-3" \
    "~/wireguard-keys/host-3.key" \
    "${HOST_WG_IP[host3]}" \
    51820 \
    "$(cat ./wgpubs/master.pub)" \
    "${VM_WG_IP[master]}" \
    "${MASTER_IP}:51820" \
    "$(cat ./wgpubs/worker1.pub)" \
    "${VM_WG_IP[worker1]}" \
    "${WORKER1_IP}:51820" \
    "$(cat ./wgpubs/worker2.pub)" \
    "${VM_WG_IP[worker2]}" \
    "${WORKER2_IP}:51820" \
    "$(cat ./wgpubs/worker3.pub)" \
    "${VM_WG_IP[worker3]}" \
    "${WORKER3_IP}:51820" \
    "$(cat ./wgpubs/host1.pub)" \
    "${HOST_WG_IP[host1]}" \
    "${HOST_LAN_IP[host1]}:51820" \
    "$(cat ./wgpubs/host2.pub)" \
    "${HOST_WG_IP[host2]}" \
    "${HOST_LAN_IP[host2]}:51820"

echo "generated the wireguard config files for each machine or vm"
echo "copying the wireguard config files to the remote hosts"

cp wgconfs/host-1.conf /tmp/wg0.conf
sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf

scp wgconfs/master.conf kubernetes@${MASTER_IP}:/tmp/wg0.conf
ssh kubernetes@${MASTER_IP} "sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf"

scp wgconfs/worker1.conf kubernetes@${WORKER1_IP}:/tmp/wg0.conf
ssh kubernetes@${WORKER1_IP} "sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf"

scp wgconfs/host-2.conf ${HOST_2}:/tmp/wg0.conf
ssh "$HOST_2" "sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf"

scp wgconfs/worker2.conf ${HOST_2}:/tmp/vm/wg0.conf
ssh "$HOST_2" "scp -i ~/.ssh/kvm-worker2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/vm/wg0.conf kubernetes@${WORKER2_IP}:/tmp/wg0.conf"
ssh "$HOST_2" "ssh -i ~/.ssh/kvm-worker2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} 'sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf'"

scp wgconfs/host-3.conf ${HOST_3}:/tmp/wg0.conf
ssh "$HOST_3" "sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf"

scp wgconfs/worker3.conf ${HOST_3}:/tmp/vm/wg0.conf
ssh "$HOST_3" "scp -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null /tmp/vm/wg0.conf kubernetes@${WORKER3_IP}:/tmp/wg0.conf"
ssh "$HOST_3" "ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} 'sudo mv /tmp/wg0.conf /etc/wireguard/wg0.conf && sudo chmod 600 /etc/wireguard/wg0.conf'"

echo "copied the wireguard config files to the remote hosts"

sudo systemctl enable --now wg-quick@wg0

ssh kubernetes@${MASTER_IP} "sudo systemctl enable --now wg-quick@wg0"
ssh kubernetes@${WORKER1_IP} "sudo systemctl enable --now wg-quick@wg0"

ssh "$HOST_2" "sudo systemctl enable --now wg-quick@wg0"
ssh "$HOST_2" "ssh -i ~/.ssh/kvm-worker2 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER2_IP} 'sudo systemctl enable --now wg-quick@wg0'"

ssh "$HOST_3" "sudo systemctl enable --now wg-quick@wg0"
ssh "$HOST_3" "ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${WORKER3_IP} 'sudo systemctl enable --now wg-quick@wg0'"


echo "!!!!!!!!!!!!!!!!!!1 FINISHED CREATING VPN FOR COMMUNICATION BETWEEN HOSTS !!!!!!!!!!!!!!!!!!!"
sleep 100

# old script

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

# Copy master IP file to local machine
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    kubernetes@${MASTER_IP}:/home/kubernetes/master-ip.txt /tmp/master-ip.txt
echo "✅ Copied master IP file locally"

# Function to update hosts file on a worker
update_worker_hosts() {
    local worker_ip=$1
    local worker_num=$2
    
    # Copy master IP file to worker
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        /tmp/master-ip.txt kubernetes@${worker_ip}:/tmp/master-ip.txt
    
    # Update hosts file on worker
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
        kubernetes@${worker_ip} 'sudo sh -c "echo \"$(cat /tmp/master-ip.txt) k8s-node-master\" >> /etc/hosts"'
    
    echo "✅ Updated hosts file on worker ${worker_num}"
}

# Update hosts file on each worker
update_worker_hosts ${WORKER1_IP} 1
update_worker_hosts ${WORKER2_IP} 2
update_worker_hosts ${WORKER3_IP} 3

# Clean up local master IP file
rm /tmp/master-ip.txt

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

echo "deleted local kubeadm join script"
rm ./kubeadm-join.sh

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

echo "Getting kubeconfig from master node..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config
chmod 600 ~/.kube/config
echo "✅ Copied kubeconfig to local machine"

sudo cp /etc/hosts /etc/hosts.bak

# Replace the last occurrence of 'k8s-node-master' with the provided master_ip
sudo tac /etc/hosts | sed "0,/\(.*\)k8s-node-master/s//${MASTER_IP} k8s-node-master/" | tac | sudo tee /etc/hosts > /dev/null

echo "Updated /etc/hosts with master IP ${MASTER_IP}"

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

echo "finished creating the cluster ✅"
end_time=$(date +%s)
elapsed=$((end_time - start_time))
echo "Cluster creation finished in ${elapsed} seconds"

# echo "Starting prometheus server"
# PROMETHEUS_TEMPLATE="prometheus/prometheus-template.yaml"
# PROMETHEUS_CONFIG="prometheus/prometheus.yaml"

# sed -e "s/NODE1_IP/$WORKER1_IP/" -e "s/NODE2_IP/$WORKER2_IP/" -e "s/NODE3_IP/$WORKER3_IP/" "$PROMETHEUS_TEMPLATE" > "$PROMETHEUS_CONFIG"

# docker run -d --name prometheus-server -p 9090:9090 -v "$PWD/prometheus/prometheus.yaml:/etc/prometheus/prometheus.yml" --memory="1g" --cpus="1.0" prom/prometheus
# echo "Prometheus server started at http://localhost:9090"
# echo "Prometheus config file created at $PROMETHEUS_CONFIG"

# echo "Running node exporter daemonset"
# kubectl apply -f daemonSets/daemonset-node-exporter.yaml
# echo "Node exporter daemonset created"