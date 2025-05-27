#!/bin/bash

virt-install --name k8s-master --memory 6144 --vcpus 4 --disk path=./master.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network type=bridge,source=br0,model=virtio --network network=default,model=virtio --cloud-init user-data=cloud-init-master.yaml,network-config=network-config-master.yaml  --graphics none --console pty,target_type=serial --noautoconsole


# virt-install --name k8s-master --memory 4096 --vcpus 4 --disk path=./master.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network type=bridge,source=br0,model=virtio --network network=default,model=virtio --cloud-init user-data=cloud-init-master.yaml  --graphics none --console pty,target_type=serial --noautoconsole
