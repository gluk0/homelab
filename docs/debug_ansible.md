
1. **Install Ansible**
   ```bash
   # Using uv (recommended)
   uv sync
   uv run ansible --version
   ```

2. **Generate SSH Key for Homelab**
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_homelab -C "homelab@$(hostname)"
   ```


4. **Set Environment Variables** (optional)
   To be used in GH action in future.
   ```bash
   export ANSIBLE_USER_PASSWORD='pass'
   ```

## Initial Setup

### 1. Prepare Raspberry Pis

Flash Lite OS 64 bit from official imager and enable ssh.

### 2. Update Bootstrap Inventory

Edit `inventory/bootstrap-hosts.yml` and update the DHCP IPs:

```yaml
pi-a:
  ansible_host: 192.168.10.100  # Update with actual DHCP IP
pi-b:
  ansible_host: 192.168.10.101  # Update with actual DHCP IP
```

Find current IP's on network:
```bash
nmap -sn 192.168.10.0/24
```

### 3. Test Connectivity

```bash
# Test SSH access (default credentials)
ssh pi@192.168.10.100

# Or use Ansible ping
uv run ansible -i inventory/bootstrap-hosts.yml pis -m ping
```

## Network Bootstrap

This step configures static IPs and creates the ansible user.

### 1. Review Bootstrap Variables

Check `group_vars/all.yml` and verify:
- `homelab_network: 10.20.0.0/24`
- `homelab_gateway: 10.20.0.1`
- Static IPs in `inventory/hosts.yml`

### 2. Run Bootstrap Playbook

**IMPORTANT:** Since the network is not yet created, you need to:

1. First, ensure your Pis are on a network where you can reach them (e.g., home WiFi or VLAN10)
2. Update `inventory/bootstrap-hosts.yml` with current IPs
3. Run the bootstrapping set for the Pi's - these are a pre-req of the cluster for WG access and PiHole DNS for any media services running on cluster with ads. :

```bash
cd /home/rich/homelab

# Dry run
uv run ansible-playbook -i inventory/bootstrap-hosts.yml \
  playbooks/bootstrap-network.yml \
  --check

# Execute
uv run ansible-playbook -i inventory/bootstrap-hosts.yml \
  playbooks/bootstrap-network.yml \
  --ask-pass --ask-become-pass
```

### 3. Reboot and Verify

```bash
# Reboot Pis
uv run ansible -i inventory/bootstrap-hosts.yml pis -a "reboot" --become --ask-pass

# Wait 60 seconds, then test new IPs
sleep 60
uv run ansible -i inventory/hosts.yml pis -m ping
```

### Setup Pi-A (WireGuard Bastion) and Pi-B (Pi-hole)
```bash
uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml
```

### Post-Setup Tasks

#### Pi-A (WireGuard)

1. **Get server public key**
   ```bash
   cat /tmp/wireguard_keys_pi-a.txt
   ```

2. **Generate client configuration**
   ```bash
   # On your laptop
   wg genkey | tee privatekey | wg pubkey > publickey

   # Create client config
   cat > wg0-client.conf << EOF
   [Interface]
   PrivateKey = $(cat privatekey)
   Address = 10.30.0.2/32
   DNS = 10.20.0.3

   [Peer]
   PublicKey = $(cat /tmp/wireguard_keys_pi-a.txt | grep "Server Public Key" | cut -d: -f2)
   Endpoint = YOUR_PUBLIC_IP:51820
   AllowedIPs = 10.20.0.0/24, 10.30.0.0/24
   PersistentKeepalive = 25
   EOF
   ```

3. **Add client to Pi-A**
   ```bash
   ssh ansible@10.20.0.2
   sudo wg set wg0 peer YOUR_CLIENT_PUBLIC_KEY allowed-ips 10.30.0.2/32

   # Or edit /etc/wireguard/wg0.conf and add:
   [Peer]
   PublicKey = YOUR_CLIENT_PUBLIC_KEY
   AllowedIPs = 10.30.0.2/32
   PersistentKeepalive = 25

   sudo systemctl restart wg-quick@wg0
   ```

4. **Configure port forwarding on router**
   - Forward UDP port 51820 to 10.20.0.2

#### Pi-B (Pi-hole)

1. **Get web interface password**
   ```bash
   cat /tmp/pihole_password_pi-b.txt
   ```

2. **Access web interface**
   - URL: http://10.20.0.3/admin
   - Login with password from above

3. **Update DHCP/DNS settings**
   - Configure your router/DHCP server to use 10.20.0.3 as DNS
   - Or manually set DNS on devices

## Proxmox Configuration

### 1. Initial Proxmox Setup

Ensure Proxmox is installed on all three mini PCs:
- Download Proxmox VE ISO from https://www.proxmox.com/
- Install on each mini PC
- Configure network with static IPs:
  - pve-01: 10.20.0.10
  - pve-02: 10.20.0.11
  - pve-03: 10.20.0.12

### 2. Configure Root SSH Access

On each Proxmox node:

```bash
# Allow root SSH with key
ssh root@10.20.0.10
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# From your control machine
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub root@10.20.0.10
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub root@10.20.0.11
ssh-copy-id -i ~/.ssh/id_ed25519_homelab.pub root@10.20.0.12
```

### 3. Test Connectivity

```bash
uv run ansible -i inventory/hosts.yml proxmox -m ping
```

### 4. Run Proxmox Setup

```bash
uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml
```

This will:
- Configure kernel modules for Kubernetes
- Set sysctl parameters
- Disable swap
- Download Ubuntu 24.04 cloud image
- Create VM template (ID: 9000)
- Configure cloud-init

### 5. Create Proxmox Cluster (Optional)

```bash
# On pve-01
pvecm create homelab-cluster

# On pve-02 and pve-03
pvecm add 10.20.0.10
```


### VM Not Getting IP

```bash
# Check cloud-init logs
qm guest exec 101 -- cat /var/log/cloud-init-output.log

# Or SSH with console
# In Proxmox web UI: VM -> Console
# Login with ubuntu user and check:
ip addr
sudo cloud-init status
```
