#!/bin/bash
set -e

GITHUB_TOKEN=${1:-$GITHUB_TOKEN}
GITHUB_USER="gluk0"
GITHUB_REPO="homelab-cluster"

if [ -z "$GITHUB_TOKEN" ]; then
    echo "usage: $0 <github_token>"
    exit 1
fi

if ! command -v flux &> /dev/null; then
    echo "installing flux cli..."
    curl -s https://fluxcd.io/install.sh | sudo bash
fi

echo "installing flux..."
flux bootstrap github \
  --token-auth \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=main \
  --path=./clusters/homelab \
  --personal

echo "done"
