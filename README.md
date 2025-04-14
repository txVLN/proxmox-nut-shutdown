# Proxmox UPS Graceful Shutdown Integration with NUT

This setup integrates Proxmox with the Network UPS Tools (NUT) system to perform a **graceful shutdown** of all VMs and containers in case of a power outage, and optionally cancel shutdown if power is restored.

## 📁 Files Included

- `upsmon.conf` - NUT monitoring client configuration.
- `upssched.conf` - Scheduler rules for conditional shutdowns.
- `upssched-cmd.sh` - Script triggered by upssched events.
- `pve-shutdown.sh` - Graceful shutdown logic for VMs, CTs, and power state checks.

---

## 🧰 Setup Instructions

### 1. Copy the Config and Scripts

```bash
cp upsmon.conf /etc/nut/upsmon.conf
cp upssched.conf /etc/nut/upssched.conf
cp upssched-cmd.sh /etc/nut/upssched-cmd.sh
cp pve-shutdown.sh /usr/local/sbin/pve-shutdown.sh
chmod +x /etc/nut/upssched-cmd.sh /usr/local/sbin/pve-shutdown.sh
```

### 2. Make Sure upsmon Runs as Root

Ensure `upsmon.conf` contains:

```ini
RUN_AS_USER root
```

### 3. Update UPS Server Address

Replace `ip.address.of.nut.server` in all files with the actual IP or hostname of your NUT server.

---

## ⚙️ Configuration Overview

### `upsmon.conf` Highlights

- Monitors remote UPS via `MONITOR` line.
- Triggers `/usr/sbin/upssched` for advanced scheduling.
- Executes shutdown via `pve-shutdown.sh` when needed.
- Notifies system users via `WALL`, logs events, and runs scripts.

### `upssched.conf` Behavior

Schedules actions on power events:

- Starts a 60-second timer after `ONBATT` to check battery level.
- Executes shutdown if battery is at or below 30%.
- Executes immediate shutdown on `LOWBATT` or `FSD`.

### `upssched-cmd.sh` Logic

- Logs all events.
- Executes `pve-shutdown.sh` if `battery.charge <= 30`.
- Cancels shutdown if power returns.

### `pve-shutdown.sh`

1. Shuts down all VMs and containers.
2. Waits up to 5 minutes for graceful shutdown.
3. Waits a configurable **grace period** (default: 180 seconds).
4. Cancels shutdown and restarts services if power returns.
5. Executes `shutdown -h now` if not.

---

## 🔄 Testing the Setup

1. Simulate a power failure by disconnecting the UPS from wall power.
2. Observe `/var/log/upssched.log` and `/var/log/pve-shutdown.log`.
3. Confirm proper shutdown behavior and power restoration handling.

---

## ✅ Final Notes

- Ensure `upsc` is installed for UPS status checks.
- Adjust timing and thresholds as needed in the script.
- Test in a safe environment before production rollout.
