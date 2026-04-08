#!/usr/bin/env bash
# authentik-setup.sh — Auto-provision all OIDC providers via Authentik API
# Usage: ./authentik-setup.sh [--dry-run]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

# Colors
pass() { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${YELLOW}[INFO]${NC} $1"; }
fail() { echo -e "${RED}[FAIL]${NC} $1"; }

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Authentik config
AUTHENTIK_URL="${AUTHENTIK_URL:-https://auth.${DOMAIN:-homelab.local}}"
AUTHENTIK_TOKEN="${AUTHENTIK_TOKEN:-}"
AUTHENTIK_USERNAME="${AUTHENTIK_USERNAME:-admin}"
AUTHENTIK_PASSWORD="${AUTHENTIK_PASSWORD:-}"

# Check requirements
if [[ -z "$AUTHENTIK_TOKEN" ]]; then
  if [[ -z "$AUTHENTIK_PASSWORD" ]]; then
    fail "AUTHENTIK_TOKEN or AUTHENTIK_USERNAME+AUTHENTIK_PASSWORD required"
    exit 1
  fi
fi

# Get token if not provided
get_token() {
  local username="$1"
  local password="$2"
  
  curl -sf -X POST "${AUTHENTIK_URL}/api/v3/token/" \
    -H "Content-Type: application/json" \
    -d "{\"username\":\"$username\",\"password\":\"$password\"}" 2>/dev/null | \
    jq -r '.token' 2>/dev/null || echo ""
}

# Create OIDC application
create_application() {
  local name="$1"
  local slug="$2"
  local redirect_uri="$3"
  local description="${4:-}"
  
  if [[ "$DRY_RUN" == true ]]; then
    info "[DRY RUN] Would create: $name"
    echo "   Client ID: (generated)"
    echo "   Client Secret: (generated)"
    echo "   Redirect URI: $redirect_uri"
    return 0
  fi
  
  # Create via Authentik API
  local payload=$(cat <<EOF
{
  "name": "$name",
  "slug": "$slug",
  "protocol": "oauth2",
  "redirect_uris": "$redirect_uri",
  "client_type": "confidential",
  "signing_key": null
}
EOF
)
  
  local response=$(curl -sf -X POST "${AUTHENTIK_URL}/api/v3/applications/" \
    -H "Authorization: Bearer ${AUTHENTIK_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "$payload" 2>/dev/null)
  
  if [[ $? -eq 0 ]]; then
    local client_id=$(echo "$response" | jq -r '.client_id // .pk')
    local client_secret=$(echo "$response" | jq -r '.client_secret')
    pass "Created provider: $name"
    echo "   Client ID: $client_id"
    echo "   Client Secret: $client_secret"
    echo "   Redirect URI: $redirect_uri"
  else
    fail "Failed to create: $name"
  fi
}

# =============================================================================
# Main
# =============================================================================

echo "=============================================="
echo "Authentik OIDC Provider Setup"
echo "=============================================="
echo ""

# Authenticate
if [[ -z "$AUTHENTIK_TOKEN" ]]; then
  info "Authenticating as $AUTHENTIK_USERNAME..."
  AUTHENTIK_TOKEN=$(get_token "$AUTHENTIK_USERNAME" "$AUTHENTIK_PASSWORD")
  if [[ -z "$AUTHENTIK_TOKEN" ]]; then
    fail "Authentication failed"
    exit 1
  fi
  pass "Authenticated"
fi

echo ""

# Service configurations
SERVICES=(
  "Grafana:grafana:https://grafana.\${DOMAIN}/login/generic_oauth:Grafana analytics platform"
  "Gitea:gitea:https://gitea.\${DOMAIN}/user/login/oauth2/authorize:Gitea Git service"
  "Nextcloud:nextcloud:https://nextcloud.\${DOMAIN}/apps/oauth2/authorize:Nextcloud cloud storage"
  "Outline:outline:https://outline.\${DOMAIN}/auth/oidc_callback:Outline wiki"
  "Portainer:portainer:https://portainer.\${DOMAIN}/:Portainer container management"
)

# Create applications
for entry in "${SERVICES[@]}"; do
  IFS=':' read -r name slug redirect description <<< "$entry"
  actual_redirect=$(eval echo "$redirect")
  create_application "$name" "$slug" "$actual_redirect" "$description"
  echo ""
done

echo "=============================================="
echo "Setup complete!"
echo ""
echo "Update your .env files with the Client IDs and Secrets above."
echo ""
echo "Next steps:"
echo "  1. Update stacks/*/.env with credentials"
echo "  2. docker compose restart <stack>"
echo "=============================================="