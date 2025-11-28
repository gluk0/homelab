#!/bin/bash
# Script to configure DNS to use Pi-hole server
# Pi-hole DNS: 10.20.0.3

set -e

PIHOLE_DNS="10.20.0.3"
BACKUP_FILE="/etc/resolv.conf.backup-$(date +%Y%m%d-%H%M%S)"

echo "Setting DNS to Pi-hole (${PIHOLE_DNS})..."

if [ ! -f /etc/resolv.conf.backup ]; then
    echo "Backing up current DNS configuration..."
    sudo cp /etc/resolv.conf "$BACKUP_FILE"
    sudo ln -sf "$BACKUP_FILE" /etc/resolv.conf.backup
fi

if systemctl is-active --quiet systemd-resolved; then
    echo "Detected systemd-resolved, configuring via resolvectl..."
    
    INTERFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    
    if [ -n "$INTERFACE" ]; then
        echo "Configuring DNS for interface: $INTERFACE"
        sudo resolvectl dns "$INTERFACE" "$PIHOLE_DNS"
        sudo resolvectl domain "$INTERFACE" "~homelab.local"
        echo "DNS configured successfully!"
    else
        echo "Could not detect network interface"
        exit 1
    fi
else
    # Direct /etc/resolv.conf modification
    echo "Configuring /etc/resolv.conf directly..."
    echo "nameserver ${PIHOLE_DNS}" | sudo tee /etc/resolv.conf > /dev/null
    echo "search homelab.local" | sudo tee -a /etc/resolv.conf > /dev/null
    
    # Make it immutable to prevent overwrites
    sudo chattr +i /etc/resolv.conf 2>/dev/null || true
    echo "DNS configured successfully!"
fi

# Test DNS resolution
echo ""
echo "Testing DNS resolution..."
if command -v dig &> /dev/null; then
    dig @${PIHOLE_DNS} site.homelab.local +short
elif command -v nslookup &> /dev/null; then
    nslookup site.homelab.local ${PIHOLE_DNS}
else
    echo "DNS testing tools not available, but configuration is complete."
fi

echo ""
echo "Current DNS configuration:"
resolvectl status 2>/dev/null || cat /etc/resolv.conf
