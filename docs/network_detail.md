# Virtual Network Layout

## Network Overview
- **Physical Network**: 10.20.0.0/24
- **Infrastructure**: Proxmox hosts, Pi bastion nodes
- **Kubernetes**: Control planes and worker nodes

## Proxmox Hosts

| Host | IP | VM ID Range | Purpose |
|------|-----|-------------|---------|
| pve-01 | 10.20.0.10 | 100-199 | Primary Proxmox node |
| pve-02 | 10.20.0.11 | 200-299 | Secondary Proxmox node |
| pve-03 | 10.20.0.12 | 300-399 | Tertiary Proxmox node |

## Kubernetes Control Planes

| Host | IP | VMID | Proxmox Host | Resources | Status |
|------|-----|------|--------------|-----------|--------|
| k8s-cp-01 | 10.20.0.25 | 100 | pve-01 | 2 cores, 4GB RAM, 40GB disk | Active |
<!-- Additional control planes commented out for now -->
<!-- k8s-cp-02 | 10.20.0.30 | 200 | pve-02 | 2 cores, 4GB RAM, 40GB disk | Disabled -->
<!-- k8s-cp-03 | 10.20.0.40 | 300 | pve-03 | 2 cores, 4GB RAM, 40GB disk | Disabled -->

## Kubernetes Worker Nodes

| Host | IP | VMID | Proxmox Host | Resources | Status |
|------|-----|------|--------------|-----------|--------|
| k8s-worker-01 | 10.20.0.26 | 101 | pve-01 | 1 core, 6GB RAM, 50GB disk | Active |
| k8s-worker-02 | 10.20.0.31 | 201 | pve-02 | 2 cores, 10GB RAM, 50GB disk | Active |

## Resource Utilization (Target: 65% of host capacity)

| Proxmox Host | Total Capacity | Allocated | Utilization |
|--------------|----------------|-----------|-------------|
| pve-01 | 4 cores, 16GB RAM | 3 cores, 10GB RAM (cp-01 + worker-01) | 75% CPU, 62.5% RAM |
| pve-02 | 4 cores, 16GB RAM | 2 cores, 10GB RAM (worker-02) | 50% CPU, 62.5% RAM |
| pve-03 | 4 cores, 16GB RAM | 0 cores, 0GB RAM | Reserved for future expansion |

## Cluster Status

- **Active Nodes:** 3 (1 control plane, 2 workers)
- **Kubernetes Version:** 1.30.2
- **CNI:** Flannel
- **Pod Network CIDR:** 10.244.0.0/16
- **Service Network CIDR:** 10.96.0.0/12

## Network Configuration Notes

- **pve-01**: VMs connect to vmbr0 without VLAN tagging (host is on same subnet)
- **pve-02**: VMs connect to vmbr0 without VLAN tagging (separate VLAN bridges vmbr0v10, vmbr0v20 exist but VMs use direct vmbr0 connection)
- **pve-03**: Reserved for future expansion

## Infrastructure Services

| Service | Host | IP |
|---------|------|-----|
| Pi Bastion A | pi-a | 10.20.0.2 |
| Pi Bastion B | pi-b | 10.20.0.3 |
| WireGuard VPN | pi-a | 10.30.0.1 (VPN network) |
