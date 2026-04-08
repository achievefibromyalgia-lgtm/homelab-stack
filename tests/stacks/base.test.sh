#!/usr/bin/env bash
# base.test.sh — Base Infrastructure Tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/docker.sh"

section "Base Infrastructure Tests"

# Get base compose path
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$PROJECT_ROOT/stacks/base/docker-compose.yml"

FAILED=0

# Test 1: docker-compose file exists
assert_file_exists "$COMPOSE_FILE" "docker-compose.yml exists" || ((FAILED++)) || true

# Test 2: All base containers can start
info "Checking base stack containers..."
BASE_CONTAINERS="traefik portainer watchtower docker-socket-proxy"
for container in $BASE_CONTAINERS; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
    assert_container_running "$container" "Container running: $container" || ((FAILED++)) || true
    assert_health "$container" "Health check: $container" || ((FAILED++)) || true
  else
    info "Container $container not running (may not be started yet)"
  fi
done

# Test 3: Traefik API responds
info "Testing Traefik API..."
if curl -sf http://localhost:80/api/ping > /dev/null 2>&1; then
  pass "Traefik API ping"
else
  # Try HTTPS
  curl -sf -k https://localhost:443/api/ping > /dev/null 2>&1 && pass "Traefik HTTPS ping" || fail "Traefik API not reachable"
fi

# Test 4: HTTP redirects to HTTPS
info "Testing HTTPS redirect..."
assert_http_redirect "http://localhost:80/" "HTTP redirects to HTTPS" || ((FAILED++)) || true

# Test 5: Portainer accessible
assert_http_200 "http://localhost:9000" "Portainer HTTP" || ((FAILED++)) || true

# Test 6: Proxy network exists
info "Checking proxy network..."
docker network ls --format '{{.Name}}' | grep -q "^proxy$" && pass "proxy network exists" || fail "proxy network missing"

exit $FAILED