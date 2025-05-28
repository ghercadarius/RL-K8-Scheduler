#!/bin/bash

HOST_IP="172.16.100.1"

sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ~/licenta/RL-K8-Scheduler/minikube/startMinikube.sh darius@${HOST_IP}:/home/darius/minikube/startMinikube.sh
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ~/licenta/RL-K8-Scheduler/minikube/stopMinikube.sh darius@${HOST_IP}:/home/darius/minikube/stopMinikube.sh

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP} "cd /home/darius/minikube && chmod +x ./startMinikube.sh ./stopMinikube.sh && bash ./startMinikube.sh"

echo "Minikube cluster started successfully."

mkdir -p ~/.kube
mkdir -p ~/.minikube
mkdir -p ~/.minikube/profiles

sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP}:/home/darius/.kube/config ~/.kube/config
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP}:/home/darius/.minikube/profiles/custom-cluster ~/.minikube/profiles
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP}:/home/darius/.minikube/ca.crt ~/.minikube/ca.crt

echo "Kubeconfig and Minikube profile copied to local machine."
echo "Minikube setup completed. You can now use kubectl to interact with your cluster."

chmod +x ./patch-kubeconfig-tls.sh
./patch-kubeconfig-tls.sh custom-cluster 172.16.100.3
echo "Kubeconfig patched for TLS verification."






