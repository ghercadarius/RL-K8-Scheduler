#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: $0 <target_base_url> <run_dir>"
  exit 1
fi

TARGET_BASE_URL="$1"
RUN_DIR="$2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
mkdir -p "$RUN_DIR"

POWER_FILE="$RUN_DIR/power_samples.csv"

"$SCRIPT_DIR/collect_power_metrics.sh" \
  "$TEST_DURATION_SECONDS" \
  "$POWER_SAMPLE_INTERVAL_SECONDS" \
  "$MINIKUBE_PROFILE" \
  "$POWER_FILE" &
POWER_PID=$!

"$SCRIPT_DIR/run_load_test.sh" \
  "$TARGET_BASE_URL" \
  "$TEST_DURATION_SECONDS" \
  "$RUN_DIR" &
LOAD_PID=$!

cleanup() {
  kill "$POWER_PID" "$LOAD_PID" >/dev/null 2>&1 || true
}
trap cleanup INT TERM

wait "$LOAD_PID"
wait "$POWER_PID"

log "Parallel measurement finished"
