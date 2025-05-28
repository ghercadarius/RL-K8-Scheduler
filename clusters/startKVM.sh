#!/bin/bash

ssh-id add ~/.ssh/kvm-cloudinit-key

CLUSTER_HOST_IP="172.16.100.1"
MASTER_IP="172.16.100.3"
WORKER_IP="172.16.100.4"

sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $PWD/scpCluster darius@${CLUSTER_HOST_IP}:/home/darius/clusterUtils
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $PWD/scpScripts darius@${CLUSTER_HOST_IP}:/home/darius/clusterUtils/scpCluster
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $PWD/utilFiles darius@${CLUSTER_HOST_IP}:/home/darius/clusterUtils/scpCluster

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${CLUSTER_HOST_IP} "cd /home/darius/clusterUtils/scpCluster && chmod +x ./startScript.sh ./stopScript.sh ./masterNode.sh ./workerNode.sh && bash ./startScript.sh"

echo "Getting kubeconfig from master node..."
ssh -i ~/.ssh/kvm-worker3 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null kubernetes@${MASTER_IP} "sudo cat /etc/kubernetes/admin.conf" > ~/.kube/config

chmod 600 ~/.kube/config
echo "✅ Copied kubeconfig to local machine"

echo 'Dar1us2oo3' | sudo -S cp /etc/hosts /etc/hosts.bak

# Replace the last occurrence of 'k8s-node-master' with the provided master_ip
echo 'Dar1us2oo3' | sudo -S tac /etc/hosts | sed "0,/\(.*\)k8s-node-master/s//${MASTER_IP} k8s-node-master/" | tac | echo 'Dar1us2oo3' | sudo -S tee /etc/hosts > /dev/null


# end for config values

echo "Starting prometheus server"
PROMETHEUS_TEMPLATE="prometheus/prometheus-template.yml"
PROMETHEUS_CONFIG="prometheus/prometheus.yml"

sed -e "s#NODE_IP#$WORKER_IP#g" "$PROMETHEUS_TEMPLATE" > "$PROMETHEUS_CONFIG"

docker run -d --name prometheus-server -p 9090:9090 -v "$PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml" --memory="1g" --cpus="1.0" prom/prometheus
echo "Prometheus server started at http://localhost:9090"
echo "Prometheus config file created at $PROMETHEUS_CONFIG"

echo "Running node exporter pod"
kubectl apply -f deployments/deployment-node-exporter.yaml
echo "Node exporter pod created"

# echo "Running resource blocker pod"
# kubectl apply -f deployments/deployment-resource-blocker.yaml
# echo "Resource blocker pod created"