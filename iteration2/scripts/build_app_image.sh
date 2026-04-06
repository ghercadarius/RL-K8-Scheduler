#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env

APP_DIR="$ITERATION_DIR/app"
log "Building image $APP_IMAGE"
if has_command docker; then
  docker build -t "$APP_IMAGE" "$APP_DIR"
else
  podman build -t "$APP_IMAGE" "$APP_DIR"
fi

log "Loading image $APP_IMAGE into Minikube profile $MINIKUBE_PROFILE"
minikube -p "$MINIKUBE_PROFILE" image load "$APP_IMAGE"

log "Image build and load complete"
