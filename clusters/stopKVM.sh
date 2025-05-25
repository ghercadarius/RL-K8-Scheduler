#!/bin/bash

HOST_1=$(ip -4 addr show wlp6s0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
HOST_2="192.168.1.145"

echo " deleting the kvm master node"

virsh shutdown k8s-master
virsh undefine k8s-master

echo " deleting the kvm worker nodes"

sshpass -p 'Dar1us2oo3' ssh "darius@$HOST_2" "echo 'Dar1us2oo3' | sudo -S virsh shutdown k8s-worker"
sshpass -p 'Dar1us2oo3' ssh "darius@$HOST_2" "echo 'Dar1us2oo3' | sudo -S virsh undefine k8s-worker"

rm -f ./master.qcow2
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sudo -S rm -f ./worker.qcow2"

echo "!!!!!! deleted the kvm worker nodes"


echo "deleting the k8s-node-master entry from the hosts file"
echo "Dar1us2oo3" | sudo -S sed -i '/k8s-node-master/d' /etc/hosts

echo "deleting the default network to flush DHCP leases"
virsh net-destroy default
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "virsh net-destroy default" || true

echo "Dar1us2oo3" | sudo pkill -f "dnsmasq.*default"
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sudo -S pkill -f 'dnsmasq.*default'" || true


echo "Dar1us2oo3" | sudo -S rm -f /var/lib/libvirt/dnsmasq/default.leases
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sudo -S rm -f /var/lib/libvirt/dnsmasq/default.leases" || true

echo "restarting the libvirtd service"

virsh net-start default
sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sydi -S virsh net-start default" || true

sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "echo 'Dar1us2oo3' | sudo -S systemctl restart libvirtd" || true

echo "Dar1us2oo3" | sudo -S systemctl restart libvirtd
echo "successfully restarted the libvirtd service and started the default network" 


rm -f ./master.qcow2 ./worker1.qcow2

sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "rm -f ./worker2.qcow2"

echo "deleted the disk files"

echo "deleting the kubectl context"
kubectl config delete-context kubernetes-admin@kubernetes
echo "deleted the kubectl context"

while true; do
    remaining_vms=$(virsh list --all | awk 'NR>2 {print $2}' | grep -E "^k8s-")
    if [ -z "$remaining_vms" ]; then
        echo "All VMs have been removed from the host."
        break
    else
        echo "Waiting for the following VMs to be removed:"
        echo "$remaining_vms"
        sleep 5
    fi
done

while true; do
    remaining_vm=$(sshpass -p 'Dar1us2oo3' ssh "$HOST_2" "virsh list --all" | awk 'NR>2 {print $2}' | grep -E "^k8s-")
    if [ -z "$remaining_vm" ]; then
        echo "All VMs have been removed from the host."
        break
    else
        echo "Waiting for the following VMs to be removed:"
        echo "$remaining_vm"
        sleep 5
    fi
done

echo "deleting prometheus container"
docker rm -f prometheus-server
echo "deleted prometheus container"

echo "deleting prometheus config file"
rm -f /etc/prometheus/prometheus.yml
echo "deleted prometheus config file"