#!/bin/bash
#
set -o allexport

ENV_FILE=".env"

if [ -f "$ENV_FILE" ]; then
  source <(grep -v -e '^//' -e '^[[:space:]]*$' "$ENV_FILE")
  echo "Environment variables from .env loaded."
else
  echo "Error: .env file not found at $ENV_FILE"
fi

set +o allexport
