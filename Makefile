.PHONY: help bootstrap setup-pis setup-proxmox setup-all ping check lint

VENV := .venv/bin/activate
ANSIBLE := $(shell [ -f $(VENV) ] && echo ". $(VENV) &&" || echo "")

help:
	@echo "Homelab Ansible Automation"
	@echo ""
	@echo "Available targets:"
	@echo "  help              - Show this help message"
	@echo "  check-deps        - Check required dependencies"
	@echo "  ping              - Test connectivity to all hosts"
	@echo "  ping-pis          - Test connectivity to Raspberry Pis"
	@echo "  ping-proxmox      - Test connectivity to Proxmox nodes"
	@echo "  bootstrap         - Bootstrap network configuration (initial setup)"
	@echo "  bootstrap-pi-a    - Bootstrap Pi-A only"
	@echo "  setup-pis         - Setup Raspberry Pis (WireGuard + Pi-hole)"
	@echo "  setup-pi-a        - Setup only Pi-A (WireGuard bastion)"
	@echo "  setup-pi-b        - Setup only Pi-B (Pi-hole DNS)"
	@echo "  setup-proxmox     - Setup Proxmox nodes and VM templates"
	@echo "  setup-proxmox-01  - Setup only pve-01"
	@echo "  setup-proxmox-02  - Setup only pve-02"
	@echo "  setup-proxmox-03  - Setup only pve-03"
	@echo "  setup-proxmox-cluster - Create Proxmox cluster from all nodes"
	@echo "  deploy-k8s-vms    - Deploy K8s VMs on all Proxmox hosts"
	@echo "  deploy-kubernetes - Deploy Kubernetes to existing VMs"
	@echo "  deploy-k8s-full   - Deploy VMs and Kubernetes (full K8s setup)"
	@echo "  setup-portainer   - Deploy Portainer on Kubernetes cluster"
	@echo "  setup-all         - Setup everything (Pis + Proxmox)"
	@echo "  status            - Check status of all hosts"
	@echo "  k8s-status        - Check Kubernetes cluster status"
	@echo "  lint              - Lint Ansible playbooks"
	@echo "  clean             - Clean temporary files"

check-deps:
	@echo "Checking dependencies..."
	@test -f .venv/bin/activate || { echo "ERROR: Virtual environment not found. Run: uv venv && source .venv/bin/activate && uv pip install -r requirements.txt"; exit 1; }
	@bash -c ". .venv/bin/activate && command -v ansible >/dev/null 2>&1" || { echo "ERROR: ansible not found in venv. Run: source .venv/bin/activate && uv pip install -r requirements.txt"; exit 1; }
	@command -v ssh >/dev/null 2>&1 || { echo "ERROR: ssh not found"; exit 1; }
	@test -f ~/.ssh/id_ed25519_homelab || { echo "WARNING: SSH key not found at ~/.ssh/id_ed25519_homelab"; }
	@echo "✓ All dependencies satisfied"

ping:
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml all -m ping"

ping-pis:
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml pis -m ping"

ping-proxmox:
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml proxmox -m ping"

bootstrap:
	@echo "Running bootstrap playbook..."
	@echo "This will configure static IPs and create ansible user"
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/bootstrap-hosts.yml playbooks/bootstrap-network.yml --ask-pass --ask-become-pass"

bootstrap-pi-a:
	@echo "Bootstrapping Pi-A only..."
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/bootstrap-hosts.yml playbooks/bootstrap-network.yml --limit pi-a --ask-pass --ask-become-pass"

setup-pis:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml"

setup-pi-a:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml --limit pi-a"

setup-pi-b:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml --limit pi-b"

setup-proxmox:
	@bash scripts/deploy-all-proxmox.sh

setup-proxmox-01:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-01"

setup-proxmox-02:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-02"

setup-proxmox-03:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --limit pve-03"

setup-proxmox-cluster:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox-cluster.yml"

setup-portainer:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-portainer.yml"

deploy-k8s-vms:
	@bash scripts/deploy-k8s-vms.sh

deploy-kubernetes:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/deploy-kubernetes.yml"

deploy-k8s-full: deploy-k8s-vms
	@echo "Waiting 60 seconds for VMs to be ready..."
	@sleep 60
	@$(MAKE) deploy-kubernetes

k8s-status:
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml k8s_control_planes[0] -m shell -a 'kubectl get nodes -o wide' -become -become_user ansible"

encrypt-vault:
	@bash -c ". .venv/bin/activate && ansible-vault encrypt vault.yml"

decrypt-vault:
	@bash -c ". .venv/bin/activate && ansible-vault decrypt vault.yml"

edit-vault:
	@bash -c ". .venv/bin/activate && ansible-vault edit vault.yml"

setup-all: setup-pis setup-proxmox

status:
	@echo "=== Raspberry Pis ==="
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml pis -a 'uptime'" 2>/dev/null || echo "Cannot reach Pis"
	@echo ""
	@echo "=== Proxmox Nodes ==="
	@bash -c ". .venv/bin/activate && ansible -i inventory/hosts.yml proxmox -a 'uptime'" 2>/dev/null || echo "Cannot reach Proxmox nodes"

lint:
	@bash -c ". .venv/bin/activate && ansible-lint playbooks/*.yml" || true
	@bash -c ". .venv/bin/activate && yamllint inventory/*.yml group_vars/*.yml" || true

clean:
	rm -f /tmp/wireguard_keys_* /tmp/pihole_password_*
	find . -type f -name "*.retry" -delete
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true

# Dry run / check mode targets
check-bootstrap:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/bootstrap-hosts.yml playbooks/bootstrap-network.yml --check --ask-pass --ask-become-pass"

check-pis:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-pis.yml --check"

check-proxmox:
	@bash -c ". .venv/bin/activate && ansible-playbook -i inventory/hosts.yml playbooks/setup-proxmox.yml --check"
