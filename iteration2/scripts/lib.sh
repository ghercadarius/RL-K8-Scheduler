#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ITERATION_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMON_ENV="$ITERATION_DIR/config/common.env"
SKUS_FILE="$ITERATION_DIR/config/skus.csv"

log() {
  echo "[$(date -u +"%Y-%m-%dT%H:%M:%SZ")] $*"
}

die() {
  log "ERROR: $*"
  exit 1
}

load_common_env() {
  if [[ ! -f "$COMMON_ENV" ]]; then
    die "Missing config file: $COMMON_ENV"
  fi
  set -a
  # shellcheck source=/dev/null
  source "$COMMON_ENV"
  set +a
}

ensure_core_dirs() {
  mkdir -p "$ITERATION_DIR/results" "$ITERATION_DIR/logs" "$ITERATION_DIR/state"
}

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

has_command() {
  command -v "$1" >/dev/null 2>&1
}

dependency_check() {
  require_command minikube
  require_command kubectl
  require_command awk
  require_command sed
  require_command grep
  require_command date
  require_command bc
  if ! has_command perf; then
    die "perf is required for power measurements"
  fi
  if ! has_command docker && ! has_command podman; then
    die "Either docker or podman is required"
  fi
}

sku_exists() {
  local sku_id="$1"
  awk -F, -v sku="$sku_id" 'NR > 1 && $1 == sku {found=1} END {exit(found ? 0 : 1)}' "$SKUS_FILE"
}

sku_cpus() {
  local sku_id="$1"
  awk -F, -v sku="$sku_id" 'NR > 1 && $1 == sku {print $2; exit}' "$SKUS_FILE"
}

sku_memory_mb() {
  local sku_id="$1"
  awk -F, -v sku="$sku_id" 'NR > 1 && $1 == sku {print $3; exit}' "$SKUS_FILE"
}

list_all_skus() {
  awk -F, 'NR > 1 {print $1}' "$SKUS_FILE"
}

cpu_to_millicores() {
  local cpu_raw="$1"
  if [[ "$cpu_raw" == *m ]]; then
    echo "${cpu_raw%m}"
  else
    awk -v v="$cpu_raw" 'BEGIN {printf "%d", v * 1000}'
  fi
}

memory_to_mib() {
  local mem_raw="$1"
  case "$mem_raw" in
    *Ki) awk -v v="${mem_raw%Ki}" 'BEGIN {printf "%d", v / 1024}' ;;
    *Mi) echo "${mem_raw%Mi}" ;;
    *Gi) awk -v v="${mem_raw%Gi}" 'BEGIN {printf "%d", v * 1024}' ;;
    *Ti) awk -v v="${mem_raw%Ti}" 'BEGIN {printf "%d", v * 1024 * 1024}' ;;
    *) awk -v v="$mem_raw" 'BEGIN {printf "%d", v / (1024 * 1024)}' ;;
  esac
}

ensure_namespace() {
  local ns="$1"
  kubectl get namespace "$ns" >/dev/null 2>&1 || kubectl create namespace "$ns" >/dev/null
}

runtime_file_path() {
  echo "$ITERATION_DIR/$RUN_STATE_FILE"
}

write_runtime_state() {
  local path
  path="$(runtime_file_path)"
  cat >"$path" <<EOF
SUITE_INITIALIZED_AT=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
MINIKUBE_PROFILE=$MINIKUBE_PROFILE
NAMESPACE=$NAMESPACE
EOF
}

start_tunnel_if_needed() {
  local pid_file="$ITERATION_DIR/$TUNNEL_PID_FILE"
  local log_file="$ITERATION_DIR/$TUNNEL_LOG_FILE"

  mkdir -p "$(dirname "$pid_file")" "$(dirname "$log_file")"

  if [[ -f "$pid_file" ]]; then
    local existing_pid
    existing_pid="$(cat "$pid_file")"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" >/dev/null 2>&1; then
      log "Minikube tunnel already running (pid=$existing_pid)"
      return 0
    fi
  fi

  log "Starting minikube tunnel for profile $MINIKUBE_PROFILE"
  if sudo -n true >/dev/null 2>&1; then
    nohup sudo -n minikube -p "$MINIKUBE_PROFILE" tunnel --bind-address="$TUNNEL_BIND_ADDRESS" >"$log_file" 2>&1 &
  else
    nohup minikube -p "$MINIKUBE_PROFILE" tunnel --bind-address="$TUNNEL_BIND_ADDRESS" >"$log_file" 2>&1 &
  fi

  local tunnel_pid=$!
  echo "$tunnel_pid" >"$pid_file"
  sleep 3

  if ! kill -0 "$tunnel_pid" >/dev/null 2>&1; then
    die "Failed to start minikube tunnel. Check $log_file"
  fi

  log "Minikube tunnel running (pid=$tunnel_pid)"
}

stop_tunnel_if_running() {
  local pid_file="$ITERATION_DIR/$TUNNEL_PID_FILE"
  if [[ ! -f "$pid_file" ]]; then
    return 0
  fi

  local pid
  pid="$(cat "$pid_file")"
  if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
    log "Stopping minikube tunnel (pid=$pid)"
    kill "$pid" >/dev/null 2>&1 || true
    wait "$pid" 2>/dev/null || true
  fi
  rm -f "$pid_file"
}
