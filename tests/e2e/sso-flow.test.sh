#!/usr/bin/env bash
# e2e/sso-flow.test.sh — SSO Login Flow E2E Test

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

section "SSO Flow E2E Test"

FAILED=0

# Get Authentik URL from environment or default
AUTHENTIK_URL="${AUTHENTIK_URL:-http://authentik.local:9000}"

info "Testing SSO flow with Authentik at $AUTHENTIK_URL"

# Test 1: Authentik is accessible
assert_http_200 "$AUTHENTIK_URL/outpost.goauthentik.io/health" "Authentik outpost health" || ((FAILED++)) || true

# Test 2: Authentik login page
assert_http_200 "$AUTHENTIK_URL/if/flow/stage/default/" "Authentik login page" || ((FAILED++)) || true

# Test 3: Redirect to Authentik from protected service
info "Testing forward auth redirect..."
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -L "$PROTECTED_URL" 2>/dev/null || echo "000")
if [[ "$STATUS" == "302" ]] || [[ "$STATUS" == "200" ]]; then
  pass "SSO redirect works (status: $STATUS)"
else
  fail "SSO redirect failed (status: $STATUS)"
  ((FAILED++)) || true
fi

exit $FAILED