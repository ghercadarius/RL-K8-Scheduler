#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
ensure_core_dirs

RUNTIME_FILE="$(runtime_file_path)"
if [[ ! -f "$RUNTIME_FILE" ]]; then
  die "Startup phase not initialized. Run scripts/startup_suite.sh first."
fi

SELECTION="${1:-all}"
CONTINUE_ON_ERROR="$CONTINUE_ON_ERROR_DEFAULT"
MAX_FAILURES=999999
RESUME_FROM=""

shift_count=0
if [[ $# -ge 1 ]]; then
  shift_count=1
fi

if (( shift_count > 0 )); then
  shift "$shift_count"
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --continue-on-error)
      CONTINUE_ON_ERROR=true
      ;;
    --stop-on-error)
      CONTINUE_ON_ERROR=false
      ;;
    --max-failures)
      MAX_FAILURES="$2"
      shift
      ;;
    --resume-from)
      RESUME_FROM="$2"
      shift
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

RUN_ID="matrix-$(date -u +"%Y%m%dT%H%M%SZ")"
MATRIX_DIR="$ITERATION_DIR/results/$RUN_ID"
LEDGER_FILE="$MATRIX_DIR/ledger.csv"
mkdir -p "$MATRIX_DIR"

if [[ "$SELECTION" == "all" ]]; then
  mapfile -t SKUS < <(list_all_skus)
else
  IFS=',' read -r -a SKUS <<< "$SELECTION"
fi

echo "sku_id,status,exit_code,run_dir,error_timestamp,error_reason" > "$LEDGER_FILE"

started=false
failures=0

for sku in "${SKUS[@]}"; do
  if [[ -n "$RESUME_FROM" && "$started" == false ]]; then
    if [[ "$sku" != "$RESUME_FROM" ]]; then
      continue
    fi
  fi
  started=true

  log "Starting SKU: $sku"
  set +e
  RUN_OUTPUT="$($SCRIPT_DIR/run_sku_test.sh "$sku" 2>"$MATRIX_DIR/${sku}.stderr.log")"
  EXIT_CODE=$?
  set -e

  RUN_DIR=""
  if [[ -n "$RUN_OUTPUT" ]]; then
    RUN_DIR="$(echo "$RUN_OUTPUT" | tail -n1)"
  fi

  if (( EXIT_CODE == 0 )); then
    echo "$sku,success,0,$RUN_DIR,," >> "$LEDGER_FILE"
  else
    failures=$((failures + 1))
    reason="see $MATRIX_DIR/${sku}.stderr.log"
    echo "$sku,failed,$EXIT_CODE,$RUN_DIR,$(date -u +"%Y-%m-%dT%H:%M:%SZ"),$reason" >> "$LEDGER_FILE"

    if (( failures >= MAX_FAILURES )); then
      log "Failure threshold reached ($failures >= $MAX_FAILURES)"
      break
    fi

    if [[ "$CONTINUE_ON_ERROR" != "true" ]]; then
      log "Stopping on first failure due to policy"
      break
    fi
  fi
done

"$SCRIPT_DIR/summarize_results.sh" "$MATRIX_DIR" "$LEDGER_FILE"

if [[ "$CONTINUE_ON_ERROR" == "true" ]]; then
  log "Matrix run finished with continue-on-error policy"
  exit 0
fi

if (( failures > 0 )); then
  exit 1
fi

log "Matrix run finished successfully"
