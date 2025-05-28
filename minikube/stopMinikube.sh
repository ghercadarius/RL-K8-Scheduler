#!/bin/bash

# Profile name for your cluster (adjust if needed)
MINIKUBE_PROFILE="custom-cluster"

echo "Stopping Minikube cluster: $MINIKUBE_PROFILE ..."
minikube stop -p "$MINIKUBE_PROFILE"

echo "Deleting Minikube cluster: $MINIKUBE_PROFILE ..."
minikube delete -p "$MINIKUBE_PROFILE"

echo "✅ Minikube cluster '$MINIKUBE_PROFILE' stopped and deleted."
