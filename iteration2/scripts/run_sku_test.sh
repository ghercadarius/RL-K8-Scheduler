#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <sku_id>"
  exit 1
fi

SKU_ID="$1"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
ensure_core_dirs

RUNTIME_FILE="$(runtime_file_path)"
if [[ ! -f "$RUNTIME_FILE" ]]; then
  die "Startup phase not initialized. Run scripts/startup_suite.sh first."
fi

if ! sku_exists "$SKU_ID"; then
  die "Unknown SKU: $SKU_ID"
fi

CPU="$(sku_cpus "$SKU_ID")"
MEMORY_MB="$(sku_memory_mb "$SKU_ID")"
RUN_ID="$(date -u +"%Y%m%dT%H%M%SZ")"
RUN_DIR="$ITERATION_DIR/results/$SKU_ID/$RUN_ID"
mkdir -p "$RUN_DIR"

log "Running SKU $SKU_ID (cpu=$CPU, memory_mb=$MEMORY_MB)"

minikube delete -p "$MINIKUBE_PROFILE" >/dev/null 2>&1 || true
minikube start \
  --profile="$MINIKUBE_PROFILE" \
  --driver=kvm2 \
  --nodes=1 \
  --cpus="$CPU" \
  --memory="$MEMORY_MB"

ensure_namespace "$NAMESPACE"
start_tunnel_if_needed

NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
kubectl label node "$NODE_NAME" sku.id="$SKU_ID" sku.cpus="$CPU" sku.memory-mb="$MEMORY_MB" --overwrite >/dev/null

if [[ "$BUILD_APP_IMAGE" == "true" ]]; then
  "$SCRIPT_DIR/build_app_image.sh"
fi

REPLICAS="$("$SCRIPT_DIR/compute_replicas.sh")"
"$SCRIPT_DIR/deploy_app.sh" "$REPLICAS" "$RUN_DIR"
ENDPOINT="$(cat "$RUN_DIR/endpoint.txt")"

"$SCRIPT_DIR/run_parallel_measurement.sh" "$ENDPOINT" "$RUN_DIR"

TOTAL_REQUESTS="$(awk -F, 'NR==2 {print $1}' "$RUN_DIR/load_summary.csv" 2>/dev/null || echo 0)"
SUCCESS_REQUESTS="$(awk -F, 'NR==2 {print $2}' "$RUN_DIR/load_summary.csv" 2>/dev/null || echo 0)"
AVG_LATENCY_MS="$(awk -F, 'NR==2 {print $3}' "$RUN_DIR/load_summary.csv" 2>/dev/null || echo 0)"
AVG_VM_WATTS="$(awk -F, 'NR>1 {sum+=$6; n++} END {if (n==0) print 0; else printf "%.6f", sum/n}' "$RUN_DIR/power_samples.csv")"
AVG_HOST_WATTS="$(awk -F, 'NR>1 {sum+=$4; n++} END {if (n==0) print 0; else printf "%.6f", sum/n}' "$RUN_DIR/power_samples.csv")"
SAMPLE_COUNT="$(awk 'END{print NR-1}' "$RUN_DIR/power_samples.csv")"

SUMMARY_FILE="$RUN_DIR/run_summary.csv"
echo "sku_id,run_id,cpu,memory_mb,replicas,total_requests,success_requests,avg_latency_ms,avg_vm_watts,avg_host_watts,power_samples,endpoint" > "$SUMMARY_FILE"
echo "$SKU_ID,$RUN_ID,$CPU,$MEMORY_MB,$REPLICAS,$TOTAL_REQUESTS,$SUCCESS_REQUESTS,$AVG_LATENCY_MS,$AVG_VM_WATTS,$AVG_HOST_WATTS,$SAMPLE_COUNT,$ENDPOINT" >> "$SUMMARY_FILE"

log "SKU run complete: $RUN_DIR"
# Print run directory for orchestration scripts.
echo "$RUN_DIR"
