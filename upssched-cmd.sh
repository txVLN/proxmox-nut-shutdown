#!/bin/bash
LOGFILE="/var/log/upssched.log"
UPS="apc-modem@192.168.3.25"

echo "[$(date)] upssched-cmd triggered: $1" >> "$LOGFILE"

case $1 in
  shutdown30)
    charge=$(upsc $UPS battery.charge 2>/dev/null)
    echo "[$(date)] Battery charge: $charge%" >> "$LOGFILE"

    if [ -n "$charge" ] && [ "$charge" -le 30 ]; then
        echo "[$(date)] Battery at or below 30%. Initiating shutdown." >> "$LOGFILE"
        /usr/local/sbin/pve-shutdown.sh
    else
        echo "[$(date)] Battery still above 30%. Shutdown canceled." >> "$LOGFILE"
    fi
    ;;
  lowbatt)
    echo "[$(date)] LOWBATT received. Forcing shutdown." >> "$LOGFILE"
    /usr/local/sbin/pve-shutdown.sh
    ;;
  forcedshutdown)
    echo "[$(date)] FSD received. Forcing shutdown." >> "$LOGFILE"
    /usr/local/sbin/pve-shutdown.sh
    ;;
  *)
    echo "[$(date)] Unknown event: $1" >> "$LOGFILE"
    ;;
esac
