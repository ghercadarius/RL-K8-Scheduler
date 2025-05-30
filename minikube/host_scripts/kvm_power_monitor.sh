#!/usr/bin/env bash
# Estimate VM-attributed power using perf every 10ms, report average at end

set -euo pipefail
export LC_ALL=C

PID=$(pgrep -f qemu-system | head -n1) || { echo "no qemu-system process found"; exit 1; }
HZ=$(getconf CLK_TCK)
CPUS=$(nproc)
INTERVAL=0.1   # 10 ms
SAMPLES=10    # 1 second

VM_JOULES_TOTAL=0

echo "VM PID $PID, host has $CPUS CPUs"
echo "Sample,Est_VM_Watts"

PREV_C=$(awk '{print $14+$15}' /proc/$PID/stat)

for ((i=1; i<=SAMPLES; i++)); do
    # Measure package energy for INTERVAL seconds using perf
    # (awk pulls the Joules value from perf output)
    PKG_JOULES=$(echo 'Dar1us2oo3' | sudo -S perf stat -a -e power/energy-pkg/ sleep $INTERVAL 2>&1 | awk '/Joules/ {print $1}')
    
    # CPU time for VM in this interval
    CUR_C=$(awk '{print $14+$15}' /proc/$PID/stat)
    DELTA_C=$(( CUR_C - PREV_C ))
    CPU_S=$(awk "BEGIN{print $DELTA_C/$HZ}")

    # CPU share for this interval (how much of the system's CPUs the VM got in this interval)
    SHARE=$(awk "BEGIN{print $CPU_S/$INTERVAL/$CPUS}")

    # VM-attributed Joules in this interval
    VM_J=$(awk "BEGIN{print $PKG_JOULES * $SHARE}")

    # Power in this interval (W = J/s)
    VM_W=$(awk "BEGIN{print $VM_J/$INTERVAL}")

    printf "%d,%.6f\n" "$i" "$VM_W"

    # For average power at end:
    VM_JOULES_TOTAL=$(awk "BEGIN{print $VM_JOULES_TOTAL + $VM_J}")

    PREV_C=$CUR_C
done

AVG_POWER=$(awk "BEGIN{print $VM_JOULES_TOTAL/10.0}")   # 100 ms

echo "-----"
echo "Average VM Power over 100ms: $AVG_POWER Watts"
