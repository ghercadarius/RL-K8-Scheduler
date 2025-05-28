#!/bin/bash

# ==== Parameters ====
CPUS_MASTER=2
RAM_MASTER=4096   # MB
CPUS_WORKER=4
RAM_WORKER=8192   # MB
MINIKUBE_PROFILE="custom-cluster"

# Static IPs for bridge NICs
MASTER_IP="172.16.100.3"
WORKER_IP="172.16.100.4"
NETMASK="29"
GATEWAY="172.16.100.1"

set -e

# ==== Start Minikube with 2 nodes ====
minikube start --profile=${MINIKUBE_PROFILE} \
  --driver=kvm2 \
  --nodes=2 \
  --cpus=${CPUS_MASTER} \
  --memory=${RAM_MASTER}

# ==== Set resources for worker node ====
minikube node stop -p ${MINIKUBE_PROFILE} ${MINIKUBE_PROFILE}-m02
minikube node modify -p ${MINIKUBE_PROFILE} --memory=${RAM_WORKER} --cpus=${CPUS_WORKER} ${MINIKUBE_PROFILE}-m02
minikube node start -p ${MINIKUBE_PROFILE} ${MINIKUBE_PROFILE}-m02
