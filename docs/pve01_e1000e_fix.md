# pve-01 e1000e NIC Hang Fix

## Problem
pve-01 M720Q keeps freezing - network driver hangs causing complete loss of connectivity on the proxmoix host and
ultimately prevents flannel from conducting communications between nodes. 

```
Nov 22 03:57:12 pve-01 kernel: e1000e 0000:00:1f.6 eno1: Detected Hardware Unit Hang
```

Intel e1000e NIC driver experiencing hardware unit hangs. System becomes unreachable, requires hard reboot.

## Root Cause
s0ix power saving mode on Intel NIC causing driver to hang under load.

`/etc/network/if-up.d/disable-e1000e-s0ix`:
```bash
#!/bin/bash
if [ "$IFACE" = "eno1" ]; then
  ethtool --set-priv-flags eno1 s0ix-enabled off
fi

- NIC: Intel I219-V (e1000e driver)
- MAC: 98:fa:9b:83:7c:11
- Kernel: 6.14.8-2-pve
