#!/bin/bash
# nextcloud-oidc-setup.sh — Configure Nextcloud to use Authentik OIDC
# Usage: ./nextcloud-oidc-setup.sh

set -euo pipefail

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

AUTHENTIK_URL="${AUTHENTIK_URL:-https://auth.${DOMAIN:-homelab.local}}"

echo "Nextcloud OIDC Setup via Authentik"
echo "=================================="

# Check if Nextcloud is running
if ! docker ps --format '{{.Names}}' | grep -q nextcloud; then
  echo "Error: Nextcloud container not running"
  exit 1
fi

# Install social_login plugin if not present
docker exec nextcloud-nginx sh -c "curl -s -o /tmp/social_login.tar.gz https://github.com/ricardofagp/nextcloud-social-login/releases/download/v5.5.2/social_login.tar.gz && tar xzf /tmp/social_login.tar.gz -C /var/www/html/apps/ && rm /tmp/social_login.tar.gz" 2>/dev/null || echo "social_login may already be installed"

# Get provider details
echo ""
echo "Authentik provider slug for Nextcloud: nextcloud"
echo "Redirect URI: https://nextcloud.\${DOMAIN}/apps/oauth2/authorize"
echo ""
echo "Configure these in Authentik admin UI or run:"
echo "  cd ../../ && ./scripts/authentik-setup.sh"
echo ""
echo "Then in Nextcloud admin:"
echo "  1. Go to: Apps → Social Login → Enable"
echo "  2. Go to: Settings → Social Login → Add custom OIDC provider"
echo "  3. Enter Client ID, Client Secret from authentik-setup.sh output"