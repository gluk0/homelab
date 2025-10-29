#!/bin/bash

set -e

echo "=========================================="
echo "Deploying to all Proxmox hosts"
echo "=========================================="

# Deploy to pve-01
echo ""
echo ">>> Deploying to pve-01 (10.20.0.10)"
uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-01

# # Deploy to pve-02
# echo ""
# echo ">>> Deploying to pve-02 (10.20.0.11)"
# uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-02

# # Deploy to pve-03
# echo ""
# echo ">>> Deploying to pve-03 (10.20.0.12)"
# uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-03

echo ""
echo "=========================================="
echo "✅ All Proxmox deployments completed!"
echo "=========================================="
