# e1000e NIC Hardware Hang Fix

Lenovo M720q with Intel I219 NICs get hardware hangs. Logs show `Detected Hardware Unit Hang` then network dies.

## Fix

Disable interrupt throttling in `/etc/modprobe.d/e1000e.conf`:
```
options e1000e InterruptThrottleRate=0,0,0,0,0,0,0,0
```

Disable offload features in `/etc/network/interfaces`:
```
auto eno1
iface eno1 inet manual 
    post-up /usr/sbin/ethtool -K eno1 tso off gso off gro off || true
```

Apply now:
```bash
ethtool -K eno1 tso off gso off gro off
update-initramfs -u
```

Verify:
```bash
ethtool -k eno1 | grep -E 'tcp-segmentation-offload|generic-segmentation-offload|generic-receive-offload'
```
