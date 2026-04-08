#!/usr/bin/env bash
# assert.sh — Test assertion library

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Assert equality
assert_eq() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  
  if [[ "$expected" == "$actual" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(assert_eq)}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-assert_eq}"
    echo "  Expected: $expected"
    echo "  Actual:   $actual"
    return 1
  fi
}

# Assert HTTP 200
assert_http_200() {
  local url="$1"
  local msg="${2:-}"
  
  local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  
  if [[ "$status" == "200" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(HTTP 200): $url}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(HTTP 200): $url}"
    echo "  Status: $status"
    return 1
  fi
}

# Assert HTTP redirect
assert_http_redirect() {
  local url="$1"
  local msg="${2:-}"
  
  local status=$(curl -s -o /dev/null -w "%{http_code}" "$url" 2>/dev/null || echo "000")
  
  if [[ "$status" == "30"* ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(HTTP redirect): $url}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(HTTP redirect): $url}"
    echo "  Status: $status (expected 3xx)"
    return 1
  fi
}

# Assert container running
assert_container_running() {
  local name="$1"
  local msg="${2:-}"
  
  local state=$(docker inspect -f '{{.State.Running}}' "$name" 2>/dev/null || echo "false")
  
  if [[ "$state" == "true" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(container running): $name}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(container running): $name}"
    echo "  State: $state"
    return 1
  fi
}

# Assert healthcheck passing
assert_health() {
  local name="$1"
  local msg="${2:-}"
  
  local status=$(docker inspect -f '{{.State.Health.Status}}' "$name" 2>/dev/null || echo "none")
  
  if [[ "$status" == "healthy" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(healthcheck): $name}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(healthcheck): $name}"
    echo "  Status: $status (expected healthy)"
    return 1
  fi
}

# Assert file exists
assert_file_exists() {
  local path="$1"
  local msg="${2:-}"
  
  if [[ -f "$path" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(file exists): $path}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(file exists): $path}"
    return 1
  fi
}

# Assert JSON key exists
assert_json_key() {
  local json="$1"
  local key="$2"
  local msg="${3:-}"
  
  local value=$(echo "$json" | jq -r ".$key" 2>/dev/null || echo "null")
  
  if [[ "$value" != "null" && "$value" != "" ]]; then
    echo -e "${GREEN}✓${NC} ${msg:-(json key): $key = $value}"
    return 0
  else
    echo -e "${RED}✗${NC} ${msg:-(json key): $key not found in JSON}"
    return 1
  fi
}