#!/bin/bash

# Set your interface here
CALICO_IFACE="enp1s0"
CALICO_MANIFEST="calico.yaml"
CALICO_URL="https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml"

# 1. Download the Calico manifest (if not already present)
curl -O ${CALICO_URL}

# 2. Insert or replace IP_AUTODETECTION_METHOD in the DaemonSet
# We'll insert it after - name: CLUSTER_TYPE
sed -i '/^\s\{12\}- name: CLUSTER_TYPE/i\
            - name: IP_AUTODETECTION_METHOD\n            value: "interface=enp1s0"' calico.yaml


