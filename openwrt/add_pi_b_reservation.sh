#!/bin/sh

# Adds a static reservation to the hosts DHCP server so it does not attempt
# to automatically assign itself an IP address in the homelab subnet.

echo "Adding DHCP reservation for Pi-A..."

uci set dhcp.pi_a=host
uci set dhcp.pi_a.name='pi-a'
uci set dhcp.pi_a.mac='d8:3a:dd:2c:a0:6a'
uci set dhcp.pi_a.ip='10.20.0.2'
uci set dhcp.pi_a.dns='1'
uci commit dhcp

echo "Restarting dnsmasq..."
/etc/init.d/dnsmasq restart

echo ""
echo "✓ DHCP reservation added successfully!"
echo ""
echo "Pi-A MAC: d8:3a:dd:2c:a0:6a"
echo "Pi-A IP:  10.20.0.2"
echo ""
echo "The Pi will get this IP on next DHCP renewal or reboot."
