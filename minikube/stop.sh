#!/bin/bash

HOST_IP="172.16.100.1"

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP} "cd /home/darius/minikube && bash ./stopMinikube.sh && rm -f *.sh"

echo "Minikube cluster stopped successfully."
# delete kubeconfig from local machine







