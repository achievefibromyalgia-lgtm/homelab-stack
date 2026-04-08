#!/usr/bin/env bash
# run-tests.sh — Homelab Stack Integration Test Runner
# Usage: ./run-tests.sh [--stack <name>|--all]

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Colors for output
pass() { echo -e "${GREEN}✓${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; }
info() { echo -e "${YELLOW}ℹ${NC} $1"; }

# Parse arguments
STACK="${STACK:-all}"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --stack) STACK="$2"; shift 2 ;;
    --all) STACK="all"; shift ;;
    -h|--help) echo "Usage: $0 [--stack <name>|--all]"; exit 0 ;;
    *) shift ;;
  esac
done

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source library functions
for lib in "$SCRIPT_DIR/lib"/*.sh; do
  source "$lib"
done

# Count tests
TOTAL=0
PASSED=0
FAILED=0

# Run stack tests
run_stack() {
  local name="$1"
  local testfile="$SCRIPT_DIR/stacks/${name}.test.sh"
  
  if [[ ! -f "$testfile" ]]; then
    info "No test for stack: $name"
    return 0
  fi
  
  info "Running $name tests..."
  
  # Run in subshell to capture exit code
  (
    source "$testfile" 2>&1
  ) && passed=$? || passed=$?
  
  if [[ $passed -eq 0 ]]; then
    pass "$name: all tests passed"
    ((PASSED++)) || true
  else
    fail "$name: tests failed"
    ((FAILED++)) || true
  fi
  
  ((TOTAL++)) || true
}

# Run all stacks
if [[ "$STACK" == "all" ]]; then
  for stack in base network storage media databases sso notifications productivity ai backup monitoring; do
    run_stack "$stack"
  done
  
  # Run E2E tests
  info "Running E2E tests..."
  for e2e in "$SCRIPT_DIR/e2e"/*.test.sh; do
    if [[ -x "$e2e" ]]; then
      bash "$e2e" 2>&1 && pass "$(basename "$e2e"): passed" || fail "$(basename "$e2e"): failed"
      ((TOTAL++)) || true
    fi
  done
else
  run_stack "$STACK"
fi

# Summary
echo ""
echo "======================================"
echo "Test Summary: $PASSED/$TOTAL passed"
if [[ $FAILED -gt 0 ]]; then
  echo -e "${RED}Failed: $FAILED${NC}"
  exit 1
else
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
fi