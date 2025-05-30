#!/bin/bash

HOST_IP="172.16.100.1"

echo "Uploading scripts to the host machine at $HOST_IP"

sshpass -p 'Dar1us2oo3' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null darius@${HOST_IP} "rm ~/kvm_power_monitor.sh ~/metrics-monitor.sh || true"

sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./kvm_power_monitor.sh darius@${HOST_IP}:
sshpass -p 'Dar1us2oo3' scp -r -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ./metrics-monitor.sh darius@${HOST_IP}:

echo "Scripts uploaded successfully."