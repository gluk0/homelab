echo "====== NETWORK CONFIGURATION ======"
cat /etc/config/network

echo ""
echo "====== DHCP CONFIGURATION ======"
cat /etc/config/dhcp

echo ""
echo "====== WIRELESS CONFIGURATION ======"
cat /etc/config/wireless

echo ""
echo "====== FIREWALL CONFIGURATION ======"
cat /etc/config/firewall

echo ""
echo "====== SWITCH CONFIGURATION ======"
swconfig dev switch0 show 2>/dev/null || echo "Switch config via swconfig not available"

echo ""
echo "====== NETWORK INTERFACES ======"
ip addr show

echo ""
echo "====== ROUTING TABLE ======"
ip route show

echo ""
echo "====== OPENWRT VERSION ======"
cat /etc/openwrt_release

echo ""
echo "====== NETWORK DEVICES ======"
ls -la /sys/class/net/

echo ""
echo "====== DONE ======"
