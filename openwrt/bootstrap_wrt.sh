#!/bin/sh
# ========================================
# VLAN 10 → Home Wi-Fi (192.168.10.1/24)
# VLAN 20 → Homelab LAN (10.20.0.1/24)
# ========================================

set -e

echo "=== BACKING UP EXISTING CONFIG ==="
mkdir -p /root/backup
cp /etc/config/network /root/backup/network.backup.$(date +%s) 2>/dev/null || true
cp /etc/config/wireless /root/backup/wireless.backup.$(date +%s) 2>/dev/null || true
cp /etc/config/dhcp /root/backup/dhcp.backup.$(date +%s) 2>/dev/null || true
cp /etc/config/firewall /root/backup/firewall.backup.$(date +%s) 2>/dev/null || true
echo "Backups stored in /root/backup/"


# ========================================
# 1. CONFIGURE HOMELAB VLAN (VLAN 20)
# ========================================
uci set network.lan.ipaddr='10.20.0.1'
uci set network.lan.netmask='255.255.255.0'

# Create VLAN 20 device
uci set network.eth1_20=device
uci set network.eth1_20.type='8021q'
uci set network.eth1_20.ifname='eth1'
uci set network.eth1_20.vid='20'
uci set network.eth1_20.name='eth1.20'

# Update LAN bridge
uci set network.br_lan=device
uci set network.br_lan.name='br-lan'
uci set network.br_lan.type='bridge'
uci set network.br_lan.ports='eth1.20 mld0'
uci set network.lan.device='br-lan'
uci set network.lan.proto='static'
uci set network.lan.ipaddr='10.20.0.1'
uci set network.lan.netmask='255.255.255.0'

# ========================================
# 2. CONFIGURE HOME VLAN (VLAN 10)
# ========================================
uci set network.eth1_10=device
uci set network.eth1_10.type='8021q'
uci set network.eth1_10.ifname='eth1'
uci set network.eth1_10.vid='10'
uci set network.eth1_10.name='eth1.10'

# Bridge for home VLAN (Wi-Fi + VLAN 10)
uci set network.br_home=device
uci set network.br_home.name='br-home'
uci set network.br_home.type='bridge'
uci set network.br_home.ports='eth1.10'

uci set network.home=interface
uci set network.home.proto='static'
uci set network.home.device='br-home'
uci set network.home.ipaddr='192.168.10.1'
uci set network.home.netmask='255.255.255.0'

# ========================================
# 3. CONFIGURE WIFI NETWORKS
# ========================================
# 2.4 GHz
uci set wireless.wifi2g=wifi-iface
uci set wireless.wifi2g.device='wifi0'
uci set wireless.wifi2g.network='home'
uci set wireless.wifi2g.mode='ap'
uci set wireless.wifi2g.ssid='MONTY'
uci set wireless.wifi2g.encryption='psk2+ccmp'
uci set wireless.wifi2g.key=$WIFI_KEY
uci set wireless.wifi2g.wds='1'
uci set wireless.wifi2g.isolate='0'
uci set wireless.wifi2g.hidden='0'
uci set wireless.wifi2g.ifname='wlan0'

# 5 GHz
uci set wireless.wifi5g=wifi-iface
uci set wireless.wifi5g.device='wifi1'
uci set wireless.wifi5g.network='home'
uci set wireless.wifi5g.mode='ap'
uci set wireless.wifi5g.ssid='MONTY-5GHz'
uci set wireless.wifi5g.encryption='psk2+ccmp'
uci set wireless.wifi5g.key=$WIFI_KEY
uci set wireless.wifi5g.wds='1'
uci set wireless.wifi5g.isolate='0'
uci set wireless.wifi5g.hidden='0'
uci set wireless.wifi5g.ifname='wlan1'

# 6 GHz
uci set wireless.wifi6g=wifi-iface
uci set wireless.wifi6g.device='wifi2'
uci set wireless.wifi6g.network='home'
uci set wireless.wifi6g.mode='ap'
uci set wireless.wifi6g.ssid='MONTY-6GHz'
uci set wireless.wifi6g.encryption='sae'
uci set wireless.wifi6g.key=$WIFI_KEY
uci set wireless.wifi6g.wds='1'
uci set wireless.wifi6g.isolate='0'
uci set wireless.wifi6g.hidden='0'
uci set wireless.wifi6g.ifname='wlan2'

# Common country/channel setup
uci set wireless.wifi0.country='UK'
uci set wireless.wifi1.country='UK'
uci set wireless.wifi2.country='UK'
uci set wireless.wifi0.channel='6'
uci set wireless.wifi1.channel='36'
uci set wireless.wifi2.channel='5'
uci commit wireless

# ========================================
# 4. CONFIGURE DHCP
# ========================================
uci set dhcp.home=dhcp
uci set dhcp.home.interface='home'
uci set dhcp.home.start='100'
uci set dhcp.home.limit='150'
uci set dhcp.home.leasetime='12h'
uci set dhcp.home.dhcpv6='disabled'
uci set dhcp.home.ra='disabled'

uci set dhcp.lan.start='50'
uci set dhcp.lan.limit='49'



uci commit dhcp

# ========================================
# 5. CONFIGURE FIREWALL ZONES
# ========================================
# Home zone

uci set firewall.@zone[0].name='home'
uci del_list firewall.@zone[0].network
uci add_list firewall.@zone[0].network='home'
uci set firewall.@zone[0].input='ACCEPT'
uci set firewall.@zone[0].output='ACCEPT'
uci set firewall.@zone[0].forward='REJECT'

# Homelab fw zone
uci set firewall.homelab=zone
uci set firewall.homelab.name='homelab'
uci set firewall.homelab.input='ACCEPT'
uci set firewall.homelab.output='ACCEPT'
uci set firewall.homelab.forward='ACCEPT'
uci add_list firewall.homelab.network='lan'

# Set forwardings from home to homelab and homelab to wan
uci set firewall.home_to_homelab=forwarding
uci set firewall.home_to_homelab.src='home'
uci set firewall.home_to_homelab.dest='homelab'

# Allow return traffic from homelab to home for established connections
uci set firewall.homelab_to_home=forwarding
uci set firewall.homelab_to_home.src='homelab'
uci set firewall.homelab_to_home.dest='home'

uci set firewall.homelab_to_wan=forwarding
uci set firewall.homelab_to_wan.src='homelab'
uci set firewall.homelab_to_wan.dest='wan'

# WG port forward Setup internal UDP traffic (UDP 51820 → 10.20.0.2)
uci set firewall.wireguard_forward=redirect
uci set firewall.wireguard_forward.name='WireGuard'
uci set firewall.wireguard_forward.src='wan'
uci set firewall.wireguard_forward.src_dport='51820'
uci set firewall.wireguard_forward.dest='homelab'
uci set firewall.wireguard_forward.dest_ip='10.20.0.2'
uci set firewall.wireguard_forward.dest_port='51820'
uci set firewall.wireguard_forward.proto='udp'
uci set firewall.wireguard_forward.target='DNAT'

uci commit firewall

# ========================================
# 6. Push changes to router.
# ========================================
uci commit network
uci commit dhcp
uci commit wireless
uci commit firewall

echo ""
echo "=== Restart for new config ==="
/etc/init.d/network restart || true
sleep 5
/etc/init.d/dnsmasq restart || true
/etc/init.d/firewall restart || true
wifi reload || true
