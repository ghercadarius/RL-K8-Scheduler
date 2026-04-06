#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env

NODE_NAME="$(kubectl get nodes -o jsonpath='{.items[0].metadata.name}')"
ALLOC_CPU_RAW="$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.cpu}')"
ALLOC_MEM_RAW="$(kubectl get node "$NODE_NAME" -o jsonpath='{.status.allocatable.memory}')"

ALLOC_CPU_M="$(cpu_to_millicores "$ALLOC_CPU_RAW")"
ALLOC_MEM_MIB="$(memory_to_mib "$ALLOC_MEM_RAW")"

CPU_CAP=$((ALLOC_CPU_M / POD_CPU_REQUEST_MILLICORES))
MEM_CAP=$((ALLOC_MEM_MIB / POD_MEMORY_REQUEST_MIB))

if (( CPU_CAP < MEM_CAP )); then
  RAW_CAP="$CPU_CAP"
else
  RAW_CAP="$MEM_CAP"
fi

if (( RAW_CAP < 1 )); then
  RAW_CAP=1
fi

SAFE_CAP="$(awk -v cap="$RAW_CAP" -v sf="$REPLICA_SAFETY_FACTOR" 'BEGIN {v=int(cap*sf); if (v < 1) v=1; print v}')"

if (( SAFE_CAP > MAX_REPLICAS_ABSOLUTE )); then
  SAFE_CAP="$MAX_REPLICAS_ABSOLUTE"
fi

echo "$SAFE_CAP"
