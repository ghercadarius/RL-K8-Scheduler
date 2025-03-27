#!/bin/bash

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
qemu-img resize master.qcow2 5G
echo "make master disk file"
cp ubuntu-base.qcow2 worker1.qcow2
qemu-img resize worker1.qcow2 5G
echo "make worker1 disk files"
cp ubuntu-base.qcow2 worker2.qcow2
qemu-img resize worker2.qcow2 5G
echo "make worker2 disk files"
cp ubuntu-base.qcow2 worker3.qcow2
qemu-img resize worker3.qcow2 5G
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
echo "10%"
sleep 30
echo "25%"
sleep 30
echo "40%"
sleep 30
echo "50%"
sleep 30
echo "60%"
sleep 30
echo "75%"
sleep 30
echo "90%"
sleep 30
echo "100%"
echo "finished running the starting scripts in the vm's"