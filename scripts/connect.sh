#!/bin/bash
# ssh helper for homelab hosts/vms

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSH_KEY="$HOME/.ssh/id_ed25519_homelab"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Host definitions
declare -A HOSTS
HOSTS=(
    # Raspberry Pis
    ["pi-a"]="ansible@10.20.0.2"
    ["pi-b"]="ansible@10.20.0.3"
    ["pia"]="ansible@10.20.0.2"
    ["pib"]="ansible@10.20.0.3"

    # Proxmox hosts
    ["pve-01"]="root@10.20.0.10"
    ["pve-02"]="root@10.20.0.11"
    ["pve-03"]="root@10.20.0.12"
    ["pve1"]="root@10.20.0.10"
    ["pve2"]="root@10.20.0.11"
    ["pve3"]="root@10.20.0.12"

    # Kubernetes nodes
    ["k8s-cp-01"]="ansible@10.20.0.25"
    ["k8s-worker-01"]="ansible@10.20.0.26"
    ["k8s-cp-02"]="ansible@10.20.0.30"
    ["k8s-worker-02"]="ansible@10.20.0.31"
    ["k8s-cp-03"]="ansible@10.20.0.40"
    ["k8s-worker-03"]="ansible@10.20.0.41"
    ["cp1"]="ansible@10.20.0.25"
    ["cp2"]="ansible@10.20.0.30"
    ["cp3"]="ansible@10.20.0.40"
    ["worker1"]="ansible@10.20.0.26"
    ["worker2"]="ansible@10.20.0.31"
    ["worker3"]="ansible@10.20.0.41"
)

declare -A HOST_DESCRIPTIONS
HOST_DESCRIPTIONS=(
    ["pi-a"]="WireGuard VPN bastion host"
    ["pi-b"]="Pi-hole DNS server & ad-blocker"
    ["pve-01"]="Proxmox VE host 1"
    ["pve-02"]="Proxmox VE host 2"
    ["pve-03"]="Proxmox VE host 3"
    ["k8s-cp-01"]="Kubernetes control plane 1"
    ["k8s-worker-01"]="Kubernetes worker node 1"
    ["k8s-cp-02"]="Kubernetes control plane 2"
    ["k8s-worker-02"]="Kubernetes worker node 2"
    ["k8s-cp-03"]="Kubernetes control plane 3"
    ["k8s-worker-03"]="Kubernetes worker node 3"
)

show_help() {
    echo "============================================"
    echo -e "${CYAN}Homelab SSH Helper${NC}"
    echo "============================================"
    echo
    echo "Usage: $0 [hostname] [command...]"
    echo
    echo "Examples:"
    echo "  $0                    # Show interactive menu"
    echo "  $0 pi-a               # SSH to Pi-A"
    echo "  $0 cp1                # SSH to k8s-cp-01 (short alias)"
    echo "  $0 pve-01 qm list     # Run command on pve-01"
    echo "  $0 worker1 sudo reboot # Reboot worker node 1"
    echo
    echo -e "${GREEN}Available Hosts:${NC}"
    echo
    echo -e "${YELLOW}Raspberry Pis:${NC}"
    printf "  %-20s %-30s %s\n" "pi-a, pia" "10.20.0.2" "WireGuard VPN bastion"
    printf "  %-20s %-30s %s\n" "pi-b, pib" "10.20.0.3" "Pi-hole DNS server"
    echo
    echo -e "${YELLOW}Proxmox Hosts:${NC}"
    printf "  %-20s %-30s %s\n" "pve-01, pve1" "root@10.20.0.10" "Proxmox VE host 1"
    printf "  %-20s %-30s %s\n" "pve-02, pve2" "root@10.20.0.11" "Proxmox VE host 2"
    printf "  %-20s %-30s %s\n" "pve-03, pve3" "root@10.20.0.12" "Proxmox VE host 3"
    echo
    echo -e "${YELLOW}Kubernetes Nodes:${NC}"
    printf "  %-20s %-30s %s\n" "k8s-cp-01, cp1" "ansible@10.20.0.25" "K8s control plane 1"
    printf "  %-20s %-30s %s\n" "k8s-worker-01, worker1" "ansible@10.20.0.26" "K8s worker 1"
    printf "  %-20s %-30s %s\n" "k8s-cp-02, cp2" "ansible@10.20.0.30" "K8s control plane 2"
    printf "  %-20s %-30s %s\n" "k8s-worker-02, worker2" "ansible@10.20.0.31" "K8s worker 2"
    printf "  %-20s %-30s %s\n" "k8s-cp-03, cp3" "ansible@10.20.0.40" "K8s control plane 3"
    printf "  %-20s %-30s %s\n" "k8s-worker-03, worker3" "ansible@10.20.0.41" "K8s worker 3"
    echo
    echo -e "${BLUE}Quick Access Commands:${NC}"
    echo "  $0 pi-a 'sudo wg show'               # Check WireGuard status"
    echo "  $0 pi-b 'pihole status'              # Check Pi-hole status"
    echo "  $0 pve-01 'qm list'                  # List VMs on Proxmox"
    echo "  $0 cp1 'kubectl get nodes'           # Check K8s cluster status"
    echo "  $0 all 'uptime'                      # Run command on all hosts"
    echo
    echo "============================================"
}

check_host() {
    local host=$1
    if ping -c 1 -W 1 $(echo "$host" | cut -d'@' -f2) &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to SSH to a host
ssh_to_host() {
    local hostname=$1
    shift
    local command="$@"

    if [ -z "${HOSTS[$hostname]}" ]; then
        echo -e "${RED}Error: Unknown host '$hostname'${NC}"
        echo "Run '$0 help' to see available hosts"
        exit 1
    fi

    local target="${HOSTS[$hostname]}"
    local ip=$(echo "$target" | cut -d'@' -f2)

    # is host up?
    if ! check_host "$target"; then
        echo -e "${RED}Warning: Host $hostname ($ip) is not reachable${NC}"
        echo "Attempting connection anyway..."
    fi

    if [ -z "$command" ]; then
        echo -e "${GREEN}Connecting to $hostname ($target)...${NC}"
        ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$target"
    else
        echo -e "${GREEN}Running on $hostname ($target): ${CYAN}$command${NC}"
        ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$target" "$command"
    fi
}

run_on_all() {
    local command="$@"
    echo -e "${YELLOW}Running on all hosts: ${CYAN}$command${NC}"
    echo "============================================"
    declare -A unique_hosts
    for key in "${!HOSTS[@]}"; do
        local target="${HOSTS[$key]}"
        unique_hosts["$target"]="$key"
    done

    for target in "${!unique_hosts[@]}"; do
        local hostname="${unique_hosts[$target]}"
        local ip=$(echo "$target" | cut -d'@' -f2)

        echo
        echo -e "${GREEN}[$hostname - $ip]${NC}"
        if check_host "$target"; then
            ssh -i "$SSH_KEY" -o ConnectTimeout=5 "$target" "$command" 2>&1 || echo -e "${RED}Command failed${NC}"
        else
            echo -e "${RED}Host unreachable${NC}"
        fi
    done

    echo
    echo "============================================"
}

# menu
show_menu() {
    echo "============================================"
    echo -e "${CYAN}Homelab SSH - Interactive Menu${NC}"
    echo "============================================"
    echo
    echo -e "${YELLOW}Raspberry Pis:${NC}"
    echo "  1) pi-a (10.20.0.2)          - WireGuard VPN bastion"
    echo "  2) pi-b (10.20.0.3)          - Pi-hole DNS server"
    echo
    echo -e "${YELLOW}Proxmox Hosts:${NC}"
    echo "  3) pve-01 (10.20.0.10)       - Proxmox VE host 1"
    echo "  4) pve-02 (10.20.0.11)       - Proxmox VE host 2"
    echo "  5) pve-03 (10.20.0.12)       - Proxmox VE host 3"
    echo
    echo -e "${YELLOW}Kubernetes Control Planes:${NC}"
    echo "  6) k8s-cp-01 (10.20.0.25)    - Control plane 1"
    echo "  7) k8s-cp-02 (10.20.0.30)    - Control plane 2"
    echo "  8) k8s-cp-03 (10.20.0.40)    - Control plane 3"
    echo
    echo -e "${YELLOW}Kubernetes Workers:${NC}"
    echo "  9) k8s-worker-01 (10.20.0.26) - Worker node 1"
    echo " 10) k8s-worker-02 (10.20.0.31) - Worker node 2"
    echo " 11) k8s-worker-03 (10.20.0.41) - Worker node 3"
    echo
    echo "  0) Exit"
    echo
    read -p "Select host (0-11): " choice

    case $choice in
        1) ssh_to_host "pi-a" ;;
        2) ssh_to_host "pi-b" ;;
        3) ssh_to_host "pve-01" ;;
        4) ssh_to_host "pve-02" ;;
        5) ssh_to_host "pve-03" ;;
        6) ssh_to_host "k8s-cp-01" ;;
        7) ssh_to_host "k8s-cp-02" ;;
        8) ssh_to_host "k8s-cp-03" ;;
        9) ssh_to_host "k8s-worker-01" ;;
        10) ssh_to_host "k8s-worker-02" ;;
        11) ssh_to_host "k8s-worker-03" ;;
        0) exit 0 ;;
        *) echo -e "${RED}Invalid selection${NC}"; exit 1 ;;
    esac
}

if [ $# -eq 0 ]; then
    show_menu
elif [ "$1" == "help" ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    show_help
elif [ "$1" == "all" ]; then
    shift
    if [ -z "$@" ]; then
        echo -e "${RED}Error: No command specified for 'all'${NC}"
        echo "Usage: $0 all 'command'"
        exit 1
    fi
    run_on_all "$@"
elif [ "$1" == "list" ]; then
    # List all hosts with reachability
    echo "============================================"
    echo -e "${CYAN}Homelab Hosts Status${NC}"
    echo "============================================"
    echo

    declare -A checked
    for hostname in "${!HOSTS[@]}"; do
        local target="${HOSTS[$hostname]}"
        if [ "${checked[$target]}" == "1" ]; then
            continue
        fi
        checked[$target]="1"
        local ip=$(echo "$target" | cut -d'@' -f2)
        local desc="${HOST_DESCRIPTIONS[$hostname]}"

        printf "%-20s %-25s " "$hostname" "$target"
        if check_host "$target"; then
            echo -e "${GREEN}✓ UP${NC}   $desc"
        else
            echo -e "${RED}✗ DOWN${NC} $desc"
        fi
    done
    echo
else
    hostname="$1"
    shift
    ssh_to_host "$hostname" "$@"
fi
