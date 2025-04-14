#!/bin/bash
# Place the script in /usr/local/sbin/
LOGFILE="/var/log/pve-shutdown.log"
UPS_NAME="apc-modem@ip.address.of.nut.server"
GRACE_PERIOD=180
CHECK_INTERVAL=10

echo "[$(date)] Starting Proxmox shutdown procedure via NUT" >> "$LOGFILE"

echo "[$(date)] Shutting down all VMs..." >> "$LOGFILE"
for vmid in $(qm list | awk 'NR>1 {print $1}'); do
    echo "[$(date)] Shutting down VM ID $vmid" >> "$LOGFILE"
    qm shutdown $vmid &
done

echo "[$(date)] Shutting down all LXC containers..." >> "$LOGFILE"
for ctid in $(pct list | awk 'NR>1 {print $1}'); do
    echo "[$(date)] Shutting down CT ID $ctid" >> "$LOGFILE"
    pct shutdown $ctid &
done

echo "[$(date)] Waiting for all guests to shut down..." >> "$LOGFILE"
timeout=300
while [ $timeout -gt 0 ]; do
    running_vms=$(qm list | awk 'NR>1 && $3 == "running" {print $1}')
    running_cts=$(pct list | awk 'NR>1 && $2 == "running" {print $1}')

    if [ -z "$running_vms" ] && [ -z "$running_cts" ]; then
        echo "[$(date)] All guests shut down successfully." >> "$LOGFILE"
        break
    fi

    echo "[$(date)] Still shutting down... ($timeout seconds left)" >> "$LOGFILE"
    sleep 10
    timeout=$((timeout - 10))
done

echo "[$(date)] Entering $GRACE_PERIOD second grace period before shutdown." >> "$LOGFILE"
remaining=$GRACE_PERIOD
while [ $remaining -gt 0 ]; do
    status=$(upsc "$UPS_NAME" ups.status 2>/dev/null)

    if echo "$status" | grep -q "OL"; then
        echo "[$(date)] Power returned. Canceling shutdown." >> "$LOGFILE"
        for vmid in $(qm list | awk 'NR>1 {print $1}'); do
            echo "[$(date)] Restarting VM ID $vmid" >> "$LOGFILE"
            qm start $vmid
        done

        for ctid in $(pct list | awk 'NR>1 {print $1}'); do
            echo "[$(date)] Restarting CT ID $ctid" >> "$LOGFILE"
            pct start $ctid
        done

        echo "[$(date)] Shutdown canceled. System remains up." >> "$LOGFILE"
        exit 0
    fi

    echo "[$(date)] Power still out. ($remaining seconds left)" >> "$LOGFILE"
    sleep $CHECK_INTERVAL
    remaining=$((remaining - CHECK_INTERVAL))
done

echo "[$(date)] Grace period over. Power not restored. Proceeding with shutdown." >> "$LOGFILE"
shutdown -h now
