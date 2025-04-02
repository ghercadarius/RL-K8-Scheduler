#!/bin/bash

sudo cp /home/kubernetes/containerd.conf /etc/modules-load.d/containerd.conf

sudo modprobe overlay
sudo modprobe br_netfilter

sudo cp /home/kubernetes/kubernetes.conf /etc/sysctl.d/kubernetes.conf

sudo sysctl --system

sudo systemctl stop apparmor && sudo systemctl disable apparmor

sudo systemctl restart containerd.service

sudo chmod +x /home/kubernetes/kubeadm-join.sh && sudo /home/kubernetes/kubeadm-join.sh

sudo echo "finished node configuration" > /home/kubernetes/finishconfig.txt