#!/bin/bash
# setup-authentik.sh — First-time Authentik initialization
# Usage: ./setup-authentik.sh [--wait]

set -euo pipefail

AUTHENTIK_URL="${AUTHENTIK_URL:-https://auth.${DOMAIN:-homelab.local}}"
TIMEOUT="${TIMEOUT:-120}"

echo "Authentik First-Time Setup"
echo "=========================="

# Wait for Authentik to be ready
echo "Waiting for Authentik to start..."
elapsed=0
while [[ $elapsed -lt $TIMEOUT ]]; do
  if curl -sf "${AUTHENTIK_URL}/outpost.goauthentik.io/health" > /dev/null 2>&1; then
    echo "Authentik is ready!"
    break
  fi
  echo -n "."
  sleep 5
  ((elapsed += 5)) || true
done

if [[ $elapsed -ge $TIMEOUT ]]; then
  echo "Timeout waiting for Authentik"
  exit 1
fi

echo ""
echo "Authentik admin UI: ${AUTHENTIK_URL}/if/admin/"
echo ""
echo "Create your admin account at first login."
echo ""
echo "Then run: ./authentik-setup.sh"