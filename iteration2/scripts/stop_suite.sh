#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env

DELETE_CLUSTER=false
if [[ "${1:-}" == "--delete-cluster" ]]; then
  DELETE_CLUSTER=true
fi

stop_tunnel_if_running

if [[ "$DELETE_CLUSTER" == "true" ]]; then
  log "Deleting Minikube profile $MINIKUBE_PROFILE"
  minikube delete -p "$MINIKUBE_PROFILE" || true
fi

log "Suite stopped"
