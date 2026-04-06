#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env
ensure_core_dirs
dependency_check

log "Starting base Minikube profile $MINIKUBE_PROFILE"
minikube start \
  --profile="$MINIKUBE_PROFILE" \
  --driver=kvm2 \
  --nodes=1 \
  --cpus="$BASE_CPUS" \
  --memory="$BASE_MEMORY_MB"

ensure_namespace "$NAMESPACE"
start_tunnel_if_needed
write_runtime_state

log "Startup complete. Common elements are ready."
