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

echo "successfully deleted the k8s cluster"

rm -f ./master.qcow2 ./worker1.qcow2 ./worker2.qcow2 ./worker3.qcow2

echo "deleted the disk files"
