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

echo "Starting prometheus server"
PROMETHEUS_TEMPLATE="prometheus/prometheus-template.yml"
PROMETHEUS_CONFIG="prometheus/prometheus.yml"
WORKER_IP="172.16.100.3"

sed -e "s#NODE_IP#$WORKER_IP#g" "$PROMETHEUS_TEMPLATE" > "$PROMETHEUS_CONFIG"

docker run -d --name prometheus-server -p 9090:9090 -v "$PWD/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml" --memory="1g" --cpus="1.0" prom/prometheus
echo "Prometheus server started at http://localhost:9090"
echo "Prometheus config file created at $PROMETHEUS_CONFIG"

echo "Running node exporter pod"
kubectl apply -f deployments/deployment-node-exporter.yaml
kubectl apply -f deployments/service-node-exporter.yaml
echo "Node exporter pod created"

echo "Running resource blocker pod"
kubectl apply -f deployments/deployment-resource-blocker.yaml
kubectl apply -f deployments/service-resource-blocker.yaml
echo "Resource blocker pod created"

bash ./jmeterStart.sh
echo "JMeter server started successfully."







