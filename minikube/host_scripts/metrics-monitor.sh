#!/bin/bash

# Function to get CPU usage %
get_cpu_usage() {
    top -bn2 | grep "Cpu(s)" | tail -n1 | awk '{print 100 - $8 "%"}'
}

# Function to get RAM usage in MB
get_ram_usage() {
    free -m | awk '/Mem:/ {print $3 " MB used of " $2 " MB (" int($3/$2*100) "%)"}'
}

# Function to get Disk MB/s for read/write (interval 1 sec)
get_disk_usage() {
    iostat -d 1 2 | awk '/Device:/ {getline; getline} {read+=$3; write+=$4} END {print "Disk Read: " read " MB/s, Write: " write " MB/s"}'
}

# Function to get Network MBps (interval 1 sec) for br0
get_net_usage() {
    iface="enp0s31f6"
    read rx1 tx1 < <(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $2, $10}' /proc/net/dev)
    sleep 1
    read rx2 tx2 < <(awk -v iface="$iface" '$1 ~ iface {gsub(":", "", $1); print $2, $10}' /proc/net/dev)
    rx_bps=$(( (rx2 - rx1) / 1024 / 1024 )) # MBps
    tx_bps=$(( (tx2 - tx1) / 1024 / 1024 )) # MBps
    echo "Net Rx: $rx_bps MBps, Tx: $tx_bps MBps (iface $iface)"
}

echo "CPU Usage: $(get_cpu_usage)"
echo "RAM Usage: $(get_ram_usage)"
echo "Disk Usage: $(get_disk_usage)"
echo "Network Usage: $(get_net_usage)"
