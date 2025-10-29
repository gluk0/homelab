#!/bin/bash

get_wifi_interface() {
  local wifi_interface
  wifi_interface=$(iw dev 2>/dev/null | awk '$1=="Interface"{print $2}')
  echo "$wifi_interface"
}

connect_to_wg() {
  local wg_config="/etc/wireguard/wg0.conf"
  if [ -f "$wg_config" ]; then
    echo "🔐 Connecting to WireGuard VPN..."
    sudo wg-quick up wg0
    if [ $? -eq 0 ]; then
      echo "✅ WireGuard VPN connected successfully! 🎉"
    else
      echo "❌ Failed to connect to WireGuard VPN. 😢"
    fi
  else
    echo "⚠️ WireGuard configuration file not found at $wg_config. Please check your setup."
  fi
}

echo "🚀 Starting homelab WireGuard connection script..."

wifi_interface=$(get_wifi_interface)
if [ -n "$wifi_interface" ]; then
  echo "📶 Detected Wi-Fi interface: $wifi_interface"
else
  echo "❌ No Wi-Fi interface detected. Please ensure Wi-Fi is enabled."
  exit 1
fi

connect_to_wg
