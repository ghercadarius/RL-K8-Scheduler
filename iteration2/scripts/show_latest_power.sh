#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <run_dir>"
  exit 1
fi

RUN_DIR="$1"
POWER_FILE="$RUN_DIR/power_samples.csv"

if [[ ! -f "$POWER_FILE" ]]; then
  echo "Missing power file: $POWER_FILE"
  exit 1
fi

tail -n +2 "$POWER_FILE" | tail -n 1 | awk -F, '{printf "timestamp=%s host_watts=%s vm_watts=%s vm_pid=%s\n", $1, $4, $6, $7}'
