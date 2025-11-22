# pve-01 e1000e NIC Hang Fix

## Problem
pve-01 M720Q keeps freezing - network driver hangs causing complete loss of connectivity.

## Date: 2024-11-22

## Issue Details
```
Nov 22 03:57:12 pve-01 kernel: e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang
```

Intel e1000e NIC driver experiencing hardware unit hangs. System becomes unreachable, requires hard reboot.

## Root Cause
s0ix power saving mode on Intel NIC causing driver to hang under load.

## Fix Applied

### 1. Immediate fix (applied Nov 22):
```bash
ssh root@10.20.0.10
ethtool --set-priv-flags eno1 s0ix-enabled off
```

### 2. Persistent fix across reboots:
Created `/etc/network/if-up.d/disable-e1000e-s0ix`:
```bash
#!/bin/bash
if [ "$IFACE" = "eno1" ]; then
  ethtool --set-priv-flags eno1 s0ix-enabled off
fi
```

Made executable:
```bash
chmod +x /etc/network/if-up.d/disable-e1000e-s0ix
```

## Verification
```bash
ethtool --show-priv-flags eno1
# Should show: s0ix-enabled: off
```

## Notes
- Previous attempt on Nov 17 used wrong parameters (EEE=0, SmartPowerDownEnable=0) - those don't exist in kernel 6.14
- s0ix is the actual culprit for e1000e hangs on modern kernels
- This is a known issue with Intel I219-V NICs on Proxmox

## Related Hardware
- NIC: Intel I219-V (e1000e driver)
- MAC: 98:fa:9b:83:7c:11
- Kernel: 6.14.8-2-pve
