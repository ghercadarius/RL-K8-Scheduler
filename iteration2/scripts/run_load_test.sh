#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <target_base_url> <duration_seconds> <output_dir>"
  exit 1
fi

TARGET_BASE_URL="$1"
DURATION_SECONDS="$2"
OUTPUT_DIR="$3"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
mkdir -p "$OUTPUT_DIR"

RAW_FILE="$OUTPUT_DIR/load_requests.csv"
SUMMARY_FILE="$OUTPUT_DIR/load_summary.csv"

echo "timestamp,thread,endpoint,status_code,latency_ms" > "$RAW_FILE"

END_TS=$(( $(date +%s) + DURATION_SECONDS ))
TARGET_URL="${TARGET_BASE_URL%/}/work"

run_worker() {
  local worker_id="$1"
  while (( $(date +%s) < END_TS )); do
    local start_ns end_ns latency_ms code ts
    start_ns=$(date +%s%N)
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$TARGET_URL" || echo "000")
    end_ns=$(date +%s%N)
    latency_ms=$(( (end_ns - start_ns) / 1000000 ))
    ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    echo "$ts,$worker_id,/work,$code,$latency_ms"
  done
}

for worker in $(seq 1 "$JMETER_THREADS"); do
  run_worker "$worker" >> "$RAW_FILE" &
done
wait

awk -F, '
  NR > 1 {
    count++
    if ($4 ~ /^2/) ok++
    sum += $5
  }
  END {
    avg = (count > 0 ? sum / count : 0)
    printf "total_requests,successful_requests,average_latency_ms\n%d,%d,%.2f\n", count, ok, avg
  }
' "$RAW_FILE" > "$SUMMARY_FILE"

log "Load test completed: $SUMMARY_FILE"
