# Pi-A Setup Guide (WireGuard Bastion)

## Current Status
- **Current IP:** `10.20.0.149` (DHCP assigned)
- **Target IP:** `10.20.0.2` (Static)
- **MAC Address:** `d8:3a:dd:2c:a0:6a`
- **Role:** WireGuard VPN Bastion / SSH Jump Host

## Prerequisites

1. **SSH Key Generated:**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_homelab -C "homelab"
   ```

2. **Pi is accessible:**
   ```bash
   ssh pi@10.20.0.149
   # Default password: raspberry (change this later)
   ```

3. **OpenWrt router configured:**
   - VLANs set up (VLAN 10 and VLAN 20)
   - DHCP running on 10.20.0.0/24 network

## Setup Process

### Step 1: Update OpenWrt DHCP Configuration

The OpenWrt bootstrap script has been updated to include a static DHCP reservation for Pi-A. Apply it:

```bash
# SSH to your OpenWrt router
ssh root@10.20.0.1

# Run the bootstrap script
cd /root
scp user@control-machine:openwrt/bootstrap_wrt.sh .
chmod +x bootstrap_wrt.sh
./bootstrap_wrt.sh
```

**Alternative (Manual):**

```bash
ssh root@10.20.0.1

uci set dhcp.pi_a=host
uci set dhcp.pi_a.name='pi-a'
uci set dhcp.pi_a.mac='d8:3a:dd:2c:a0:6a'
uci set dhcp.pi_a.ip='10.20.0.2'
uci set dhcp.pi_a.dns='1'
uci commit dhcp
/etc/init.d/dnsmasq restart
```

### Step 2: Bootstrap Pi Network Configuration

Run the Ansible bootstrap playbook to:
- Configure static IP on the Pi
- Create `ansible` user with sudo access
- Install SSH key
- Set hostname

```bash
# From your control machine
cd /home/rich/homelab

# Run bootstrap playbook (will prompt for password)
uv run ansible-playbook -i inventory/bootstrap-hosts.yml \
  playbooks/bootstrap-network.yml \
  --limit pi-a \
  --ask-pass \
  --ask-become-pass
```main setup playbook



### Step 3: Run Main Setup (WireGuard Configuration)

Now run the main setup playbook to install and configure WireGuard:

```bash
cd /home/rich/homelab

# Run the full Pi setup playbook
uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml --limit pi-a

# Or use the Makefile
make setup-pis
```

### Step 5: Configure Port Forwarding on OpenWrt

Forward UDP port 51820 from WAN to Pi-A (in setup script also just for note how to check.)

```bash
ssh root@10.20.0.1
cat /etc/config/firewall | grep -A10 wireguard
```
