#!/usr/bin/env bash

set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 <duration_seconds> <sample_interval_seconds> <profile> <output_csv>"
  exit 1
fi

DURATION_SECONDS="$1"
SAMPLE_INTERVAL_SECONDS="$2"
PROFILE="$3"
OUTPUT_CSV="$4"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$SCRIPT_DIR/lib.sh"

load_common_env

SAMPLE_COUNT=$(( DURATION_SECONDS / SAMPLE_INTERVAL_SECONDS ))
if (( SAMPLE_COUNT < 1 )); then
  die "Invalid sample count"
fi

if ! sudo -n true >/dev/null 2>&1; then
  die "Passwordless sudo is required for perf sampling"
fi

find_vm_pid() {
  local pid
  pid="$(pgrep -f "qemu.*$PROFILE" | head -n1 || true)"
  if [[ -z "$pid" ]]; then
    pid="$(pgrep -f qemu-system | head -n1 || true)"
  fi
  echo "$pid"
}

VM_PID="$(find_vm_pid)"
HZ="$(getconf CLK_TCK)"
CPU_COUNT="$(nproc)"

echo "timestamp,sample,host_pkg_joules,host_pkg_watts,vm_cpu_share,vm_attributed_watts,vm_pid" > "$OUTPUT_CSV"

prev_cpu_ticks=0
if [[ -n "$VM_PID" ]]; then
  prev_cpu_ticks="$(awk '{print $14+$15}' "/proc/$VM_PID/stat" 2>/dev/null || echo 0)"
fi

for sample in $(seq 1 "$SAMPLE_COUNT"); do
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  pkg_joules=$(sudo -n perf stat -a -e power/energy-pkg/ sleep "$SAMPLE_INTERVAL_SECONDS" 2>&1 | awk '/Joules/ {print $1; exit}')
  if [[ -z "$pkg_joules" ]]; then
    pkg_joules=0
  fi

  host_watts=$(awk -v j="$pkg_joules" -v t="$SAMPLE_INTERVAL_SECONDS" 'BEGIN {if (t == 0) print 0; else printf "%.6f", j/t}')

  vm_share=0
  vm_watts=0
  if [[ -n "$VM_PID" ]] && [[ -r "/proc/$VM_PID/stat" ]]; then
    cur_cpu_ticks="$(awk '{print $14+$15}' "/proc/$VM_PID/stat" 2>/dev/null || echo "$prev_cpu_ticks")"
    delta_ticks=$(( cur_cpu_ticks - prev_cpu_ticks ))
    vm_share=$(awk -v d="$delta_ticks" -v hz="$HZ" -v t="$SAMPLE_INTERVAL_SECONDS" -v cpus="$CPU_COUNT" 'BEGIN {if (t == 0 || cpus == 0) print 0; else printf "%.6f", (d/hz)/t/cpus}')
    vm_watts=$(awk -v w="$host_watts" -v s="$vm_share" 'BEGIN {printf "%.6f", w*s}')
    prev_cpu_ticks="$cur_cpu_ticks"
  fi

  echo "$ts,$sample,$pkg_joules,$host_watts,$vm_share,$vm_watts,$VM_PID" >> "$OUTPUT_CSV"
done

log "Power metrics collected: $OUTPUT_CSV"
