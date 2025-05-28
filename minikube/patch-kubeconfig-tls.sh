#!/bin/bash
# Usage: ./patch-kubeconfig-tls.sh [context_name] [api_server_ip]
# Example: ./patch-kubeconfig-tls.sh custom-cluster 172.16.100.3

set -e

KUBECONFIG_FILE="${HOME}/.kube/config"
CONTEXT_NAME="$1"
API_SERVER_IP="$2"
PORT="8443"

if [[ -z "$CONTEXT_NAME" || -z "$API_SERVER_IP" ]]; then
    echo "Usage: $0 [context_name] [api_server_ip]"
    exit 1
fi

# Backup original config
cp "$KUBECONFIG_FILE" "${KUBECONFIG_FILE}.bak.$(date +%s)"

# Get the correct cluster name for the context
CLUSTER_NAME=$(yq '.contexts[] | select(.name=="'"$CONTEXT_NAME"'") | .context.cluster' "$KUBECONFIG_FILE")

if [[ -z "$CLUSTER_NAME" ]]; then
    echo "Error: Context $CONTEXT_NAME not found in kubeconfig!"
    exit 2
fi

# Patch server, remove CA lines, add insecure-skip-tls-verify
yq -i '
(.clusters[] | select(.name == "'"$CLUSTER_NAME"'") | .cluster) |=
    (.server = "https://'"$API_SERVER_IP"':'"$PORT"'"
     | del(.certificate-authority)
     | del(.["certificate-authority-data"])
     | .["insecure-skip-tls-verify"] = true )
' "$KUBECONFIG_FILE"

echo "Patched $KUBECONFIG_FILE for context '$CONTEXT_NAME' (cluster '$CLUSTER_NAME') with API server IP $API_SERVER_IP, and set insecure-skip-tls-verify: true."
