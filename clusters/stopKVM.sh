#!/bin/bash


echo " deleting the kvm master node"

virsh shutdown k8s-master
virsh undefine k8s-master

echo " deleting the kvm worker nodes"

virsh shutdown k8s-worker1
virsh undefine k8s-worker1

virsh shutdown k8s-worker2
virsh undefine k8s-worker2

virsh shutdown k8s-worker3
virsh undefine k8s-worker3

echo "deleting the k8s-node-master entry from the hosts file"
echo "Dar1us2oo3" | sudo -S sed -i '/k8s-node-master/d' /etc/hosts

echo "deleting the default network to flush DHCP leases"
virsh net-destroy default

echo "Dar1us2oo3" | sudo pkill -f "dnsmasq.*default"


echo "Dar1us2oo3" | sudo -S rm -f /var/lib/libvirt/dnsmasq/default.leases

echo "restarting the libvirtd service"

virsh net-start default

echo "Dar1us2oo3" | sudo -S systemctl restart libvirtd
echo "successfully restarted the libvirtd service and started the default network" 


rm -f ./master.qcow2 ./worker1.qcow2 ./worker2.qcow2 ./worker3.qcow2

echo "deleted the disk files"

echo "deleting the kubectl context"
kubectl config delete-context kubernetes-admin@kubernetes
echo "deleted the kubectl context"

while true; do
    remaining_vms=$(virsh list --all | awk 'NR>2 {print $2}' | grep -E "^k8s-")
    if [ -z "$remaining_vms" ]; then
        echo "All VMs have been removed"
        break
    else
        echo "Waiting for the following VMs to be removed:"
        echo "$remaining_vms"
        sleep 5
    fi
done

echo "deleting prometheus container"
docker rm -f prometheus-server
echo "deleted prometheus container"

echo "deleting prometheus config file"
rm -f /etc/prometheus/prometheus.yml
echo "deleted prometheus config file"