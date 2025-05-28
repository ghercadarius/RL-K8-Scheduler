#!/bin/bash

virsh --connect qemu:///system shutdown k8s-master
virsh --connect qemu:///system undefine k8s-master

echo " deleting the kvm worker nodes"

virsh --connect qemu:///system shutdown k8s-worker
virsh --connect qemu:///system undefine k8s-worker

rm -f ./master.qcow2
rm -f ./worker.qcow2

echo "!!!!!! deleted the kvm worker nodes"


echo "deleting the k8s-node-master entry from the hosts file"
echo "Dar1us2oo3" | sudo -S sed -i '/k8s-node-master/d' /etc/hosts

echo "deleting the default network to flush DHCP leases"
virsh --connect qemu:///system net-destroy default

echo "Dar1us2oo3" | sudo pkill -f "dnsmasq.*default"


echo "Dar1us2oo3" | sudo -S rm -f /var/lib/libvirt/dnsmasq/default.leases

echo "restarting the libvirtd service"

virsh --connect qemu:///system net-start default

echo "Dar1us2oo3" | sudo -S systemctl restart libvirtd
echo "successfully restarted the libvirtd service and started the default network" 

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

echo "All VMs have been removed from the host."