#!/bin/bash

HOST_IP="172.16.100.1"

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP} "cd /home/darius/minikube && bash ./stopMinikube.sh && rm -f *.sh"

echo "Minikube cluster stopped successfully."
# delete kubeconfig from local machine

echo "deleting the kubectl context"
kubectl config delete-context kubernetes-admin@kubernetes
echo "deleted the kubectl context"

echo "deleting prometheus container"
docker rm -f prometheus-server
echo "deleted prometheus container"

echo "deleting prometheus config file"
rm -f prometheus/prometheus.yml
echo "deleted prometheus config file"









