#!/bin/bash

MY_IP=$(hostname -I | awk '{print $1}')

# Save master IP to a file
echo "$MY_IP" | sudo tee /home/kubernetes/master-ip.txt
sudo chown kubernetes:kubernetes /home/kubernetes/master-ip.txt

sudo cp /home/kubernetes/containerd.conf /etc/modules-load.d/containerd.conf

sudo modprobe overlay
sudo modprobe br_netfilter

sudo cp /home/kubernetes/kubernetes.conf /etc/sysctl.d/kubernetes.conf

sudo sysctl --system

sudo cp /home/kubernetes/kubelet /etc/default/kubelet

sudo systemctl daemon-reload && sudo systemctl restart kubelet

sudo cp /home/kubernetes/daemon.json /etc/docker/daemon.json

sudo systemctl daemon-reload && sudo systemctl restart docker

sudo cp /home/kubernetes/10-kubeadm.conf /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload && sudo systemctl restart kubelet

sudo kubeadm init --control-plane-endpoint=k8s-node-master --pod-network-cidr=192.168.0.0/16 --upload-certs --apiserver-advertise-address=$MY_IP

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl taint nodes --all node-role.kubernetes.io/control-plane-

sudo kubeadm token create --print-join-command > /home/kubernetes/kubeadm-join.sh

echo "finished node configuration" > /home/kubernetes/finishconfig.txt
