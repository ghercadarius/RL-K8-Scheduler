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
JTL_FILE="$OUTPUT_DIR/jmeter_results.csv"
JMETER_LOG_FILE="$OUTPUT_DIR/jmeter.log"
JMETER_PLAN="$ITERATION_DIR/jmeter/test-plan.jmx"

if ! has_command jmeter; then
  die "jmeter is required for load testing"
fi

if [[ ! -f "$JMETER_PLAN" ]]; then
  die "JMeter plan not found: $JMETER_PLAN"
fi

target_no_proto="${TARGET_BASE_URL#*://}"
target_proto="${TARGET_BASE_URL%%://*}"
if [[ "$target_proto" == "$TARGET_BASE_URL" ]]; then
  target_proto="http"
fi

host_port_path="$target_no_proto"
host_port="${host_port_path%%/*}"
base_path=""
if [[ "$host_port_path" == */* ]]; then
  base_path="/${host_port_path#*/}"
fi

target_host="${host_port%%:*}"
target_port="${host_port##*:}"
if [[ "$target_host" == "$target_port" ]]; then
  if [[ "$target_proto" == "https" ]]; then
    target_port="443"
  else
    target_port="80"
  fi
fi

log "Starting JMeter load: host=$target_host port=$target_port duration=${DURATION_SECONDS}s threads=$JMETER_THREADS"

jmeter -n \
  -t "$JMETER_PLAN" \
  -l "$JTL_FILE" \
  -j "$JMETER_LOG_FILE" \
  -Jprotocol="$target_proto" \
  -Jhost="$target_host" \
  -Jport="$target_port" \
  -Jbase_path="$base_path" \
  -Jthreads="$JMETER_THREADS" \
  -Jramp_up="$JMETER_RAMP_UP_SECONDS" \
  -Jduration="$DURATION_SECONDS" \
  -Jwork_min_intensity="$JMETER_WORK_MIN_INTENSITY" \
  -Jwork_max_intensity="$JMETER_WORK_MAX_INTENSITY" \
  -Jbatch_min_intensity="$JMETER_BATCH_MIN_INTENSITY" \
  -Jbatch_max_intensity="$JMETER_BATCH_MAX_INTENSITY" \
  -Jjmeter.save.saveservice.output_format=csv \
  -Jjmeter.save.saveservice.print_field_names=true \
  -Jjmeter.save.saveservice.time=true \
  -Jjmeter.save.saveservice.timestamp_format=ms \
  -Jjmeter.save.saveservice.label=true \
  -Jjmeter.save.saveservice.response_code=true \
  -Jjmeter.save.saveservice.thread_name=true \
  -Jjmeter.save.saveservice.successful=true \
  -Jjmeter.save.saveservice.elapsed=true

echo "timestamp,thread,endpoint,status_code,latency_ms" > "$RAW_FILE"

awk -F, '
  NR == 1 {
    for (i = 1; i <= NF; i++) {
      idx[$i] = i
    }
    next
  }
  {
    ts = $(idx["timeStamp"])
    thread = $(idx["threadName"])
    label = $(idx["label"])
    code = $(idx["responseCode"])
    elapsed = $(idx["elapsed"])
    printf "%s,%s,%s,%s,%s\n", ts, thread, label, code, elapsed
  }
' "$JTL_FILE" >> "$RAW_FILE"

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
