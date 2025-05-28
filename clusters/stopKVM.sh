#!/bin/bash

CLUSTER_HOST_IP="172.16.100.1"

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${CLUSTER_HOST_IP} "bash /home/darius/clusterUtils/scpCluster/stopScript.sh"
echo "stopped the kvm cluster"
sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${CLUSTER_HOST_IP} "rm -rf /home/darius/clusterUtils/scpCluster"

echo "deleting the kubectl context"
kubectl config delete-context kubernetes-admin@kubernetes
echo "deleted the kubectl context"

echo "deleting prometheus container"
docker rm -f prometheus-server
echo "deleted prometheus container"

echo "deleting prometheus config file"
rm -f prometheus/prometheus.yml
echo "deleted prometheus config file"