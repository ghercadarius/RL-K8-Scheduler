#!/bin/bash

virt-install --name k8s-worker1 --memory 2048 --vcpus 2 --disk path=./worker1.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network network=default --cloud-init user-data=cloud-init-worker1.yaml --noautoconsole

virt-install --name k8s-worker2 --memory 2048 --vcpus 2 --disk path=./worker2.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network network=default --cloud-init user-data=cloud-init-worker2.yaml --noautoconsole

virt-install --name k8s-worker3 --memory 2048 --vcpus 2 --disk path=./worker3.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network network=default --cloud-init user-data=cloud-init-worker3.yaml --noautoconsole