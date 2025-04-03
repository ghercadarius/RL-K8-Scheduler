#!/bin/bash

virt-install --name k8s-master --memory 4096 --vcpus 4 --disk path=./master.qcow2,format=qcow2,size=1 --os-variant ubuntu22.04 --import --network network=default --cloud-init user-data=cloud-init-master.yaml --noautoconsole
