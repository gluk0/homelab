uci show network | grep -E "(lan|home|eth1\.10)"

echo ""
echo "====== CURRENT WIRELESS CONFIG ======"
uci show wireless | grep -E "network="

echo ""
echo "====== WIFI INTERFACE STATUS ======"
iw dev

echo ""
echo "====== BRIDGE STATUS ======"
brctl show

echo ""
echo "====== INTERFACE STATUS ======"
ip addr show | grep -E "^[0-9]+:|inet "

echo ""
echo "====== WIFI CLIENTS ======"
iw dev wlan0 station dump 2>/dev/null | grep Station || echo "No clients on wlan0"

iw dev wlan1 station dump 2>/dev/null | grep Station || echo "No clients on wlan1"

iw dev wlan2 station dump 2>/dev/null | grep Station || echo "No clients on wlan2"
