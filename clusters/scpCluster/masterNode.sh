#!/bin/bash

echo "Current user: $(whoami) - masterNode.sh"
id


virt-install --connect qemu:///system --name k8s-master --memory 4096 --vcpus 2 --disk path=./master.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network type=bridge,source=br0,model=virtio --network network=default,model=virtio --cloud-init user-data=cloud-init-master.yaml,network-config=network-config-master.yaml  --graphics none --console pty,target_type=serial --noautoconsole


# virt-install --name k8s-master --memory 4096 --vcpus 4 --disk path=./master.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network type=bridge,source=br0,model=virtio --network network=default,model=virtio --cloud-init user-data=cloud-init-master.yaml  --graphics none --console pty,target_type=serial --noautoconsole
