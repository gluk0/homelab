#!/bin/bash
# Fix CNI network bridge issues after cluster reset
# This script removes stale CNI bridges and restarts containerd/kubelet

set -e

echo "Fixing CNI network interfaces..."
echo "Stopping kubelet..."
sudo systemctl stop kubelet || true

echo "Stopping containerd..."
sudo systemctl stop containerd || true

echo "Removing CNI network interfaces..."
sudo ip link set cni0 down 2>/dev/null || true
sudo ip link delete cni0 2>/dev/null || true
sudo ip link set flannel.1 down 2>/dev/null || true
sudo ip link delete flannel.1 2>/dev/null || true

echo "Cleaning CNI configuration..."
sudo rm -rf /var/lib/cni/networks/* 2>/dev/null || true
sudo rm -rf /var/lib/cni/results/* 2>/dev/null || true
sudo rm -rf /opt/cni/bin/* 2>/dev/null || true

echo "Starting containerd..."
sudo systemctl start containerd

echo "Starting kubelet..."
sudo systemctl start kubelet

echo "CNI network interfaces fixed successfully!"
echo "Waiting 10 seconds for services to stabilize..."
sleep 10
