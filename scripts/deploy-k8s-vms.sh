#!/bin/bash

set -e

echo "=========================================="
echo "Creating K8s VMs on all Proxmox hosts"
echo "=========================================="

if grep -q "\$ANSIBLE_VAULT" vault.yml 2>/dev/null; then
    echo "Vault is encrypted, you'll need to provide the vault password"
    uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-k8s-vms.yml --ask-vault-pass
else
    uv run ansible-playbook -i inventory/hosts.yml playbooks/setup-k8s-vms.yml
fi

echo ""
echo "=========================================="
echo "✅ K8s VM deployment completed!"
echo "=========================================="
