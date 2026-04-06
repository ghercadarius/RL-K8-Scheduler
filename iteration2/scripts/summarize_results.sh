#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
ensure_core_dirs

MATRIX_DIR="${1:-$ITERATION_DIR/results/matrix-latest}"
LEDGER_FILE="${2:-$MATRIX_DIR/ledger.csv}"
SUMMARY_OUT="$MATRIX_DIR/summary_success.csv"
FAILED_OUT="$MATRIX_DIR/summary_failed.csv"

mkdir -p "$MATRIX_DIR"

echo "sku_id,run_id,cpu,memory_mb,replicas,total_requests,success_requests,avg_latency_ms,avg_vm_watts,avg_host_watts,power_samples,endpoint,run_dir" > "$SUMMARY_OUT"
echo "sku_id,status,exit_code,run_dir,error_timestamp,error_reason" > "$FAILED_OUT"

if [[ -f "$LEDGER_FILE" ]]; then
  while IFS=, read -r sku_id status exit_code run_dir err_ts reason; do
    [[ "$sku_id" == "sku_id" ]] && continue
    if [[ "$status" == "success" && -f "$run_dir/run_summary.csv" ]]; then
      tail -n +2 "$run_dir/run_summary.csv" | awk -v d="$run_dir" -F, '{print $0 "," d}' >> "$SUMMARY_OUT"
    else
      echo "$sku_id,$status,$exit_code,$run_dir,$err_ts,$reason" >> "$FAILED_OUT"
    fi
  done < "$LEDGER_FILE"
fi

log "Summary written: $SUMMARY_OUT"
log "Failures written: $FAILED_OUT"
