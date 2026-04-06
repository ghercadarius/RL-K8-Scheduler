#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <replicas> <output_dir>"
  exit 1
fi

REPLICAS="$1"
OUTPUT_DIR="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
mkdir -p "$OUTPUT_DIR"

DEPLOY_OUT="$OUTPUT_DIR/deployment.rendered.yaml"
SERVICE_OUT="$OUTPUT_DIR/service.rendered.yaml"

sed \
  -e "s|__APP_NAME__|$APP_NAME|g" \
  -e "s|__NAMESPACE__|$NAMESPACE|g" \
  -e "s|__APP_IMAGE__|$APP_IMAGE|g" \
  -e "s|__REPLICAS__|$REPLICAS|g" \
  -e "s|__APP_PORT__|$APP_PORT|g" \
  -e "s|__CPU_REQUEST_M__|$POD_CPU_REQUEST_MILLICORES|g" \
  -e "s|__CPU_LIMIT_M__|$POD_CPU_LIMIT_MILLICORES|g" \
  -e "s|__MEM_REQUEST_MI__|$POD_MEMORY_REQUEST_MIB|g" \
  -e "s|__MEM_LIMIT_MI__|$POD_MEMORY_LIMIT_MIB|g" \
  "$ITERATION_DIR/k8s/deployment.tpl.yaml" > "$DEPLOY_OUT"

sed \
  -e "s|__APP_NAME__|$APP_NAME|g" \
  -e "s|__NAMESPACE__|$NAMESPACE|g" \
  -e "s|__SERVICE_PORT__|$SERVICE_PORT|g" \
  -e "s|__APP_PORT__|$APP_PORT|g" \
  "$ITERATION_DIR/k8s/service.tpl.yaml" > "$SERVICE_OUT"

kubectl apply -f "$DEPLOY_OUT"
kubectl apply -f "$SERVICE_OUT"

kubectl rollout status deployment/$APP_NAME -n "$NAMESPACE" --timeout=240s

# Wait for external endpoint from tunnel; fallback to minikube service URL.
ENDPOINT=""
for _ in $(seq 1 20); do
  LB_IP="$(kubectl get svc "$APP_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"
  if [[ -n "$LB_IP" ]]; then
    ENDPOINT="http://$LB_IP:$SERVICE_PORT"
    break
  fi
  sleep 2
done

if [[ -z "$ENDPOINT" ]]; then
  ENDPOINT="$(minikube -p "$MINIKUBE_PROFILE" service "$APP_NAME" -n "$NAMESPACE" --url | head -n1)"
fi

if [[ -z "$ENDPOINT" ]]; then
  echo "Could not resolve service endpoint" >&2
  exit 1
fi

echo "$ENDPOINT" > "$OUTPUT_DIR/endpoint.txt"
log "Application endpoint: $ENDPOINT"
