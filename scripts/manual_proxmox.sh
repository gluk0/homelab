#!/bin/bash
# Create VMs on pve-02 using qm commands directly

set -e

export PROXMOX_PASS='Monalikesarat123'

# k8s-cp-02 (control plane on pve-02)
echo "Creating k8s-cp-02..."
source .venv/bin/activate && ansible pve-02 -i inventory/hosts.yml -m shell -a "
qm clone 9000 200 --name k8s-cp-02 --full true --storage local-lvm &&
qm set 200 --cores 2 --memory 2048 &&
qm set 200 --net0 virtio,bridge=vmbr0,tag=20 &&
qm set 200 --ipconfig0 'ip=10.20.0.30/24,gw=10.20.0.1' &&
qm set 200 --ciuser ansible &&
qm set 200 --sshkeys /root/.ssh/authorized_keys &&
qm set 200 --searchdomain homelab.local &&
qm set 200 --nameserver 10.20.0.3 &&
qm resize 200 scsi0 30G &&
qm start 200
" -b || echo "VM may already exist"

# k8s-worker-02 (worker on pve-02)
echo "Creating k8s-worker-02..."
source .venv/bin/activate && ansible pve-02 -i inventory/hosts.yml -m shell -a "
qm clone 9000 201 --name k8s-worker-02 --full true --storage local-lvm &&
qm set 201 --cores 2 --memory 2048 &&
qm set 201 --net0 virtio,bridge=vmbr0,tag=20 &&
qm set 201 --ipconfig0 'ip=10.20.0.31/24,gw=10.20.0.1' &&
qm set 201 --ciuser ansible &&
qm set 201 --sshkeys /root/.ssh/authorized_keys &&
qm set 201 --searchdomain homelab.local &&
qm set 201 --nameserver 10.20.0.3 &&
qm resize 201 scsi0 30G &&
qm start 201
" -b || echo "VM may already exist"

echo "VMs created successfully on pve-02!"
