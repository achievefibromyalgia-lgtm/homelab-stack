#!/usr/bin/env bash
# backup.test.sh — Backup & DR Tests

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"
source "$SCRIPT_DIR/lib/docker.sh"

section "Backup Stack Tests"

PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
COMPOSE_FILE="$PROJECT_ROOT/stacks/backup/docker-compose.yml"
FAILED=0

# Test 1: backup.sh exists and executable
BACKUP_SCRIPT="$PROJECT_ROOT/scripts/backup.sh"
assert_file_exists "$BACKUP_SCRIPT" "backup.sh exists" || ((FAILED++)) || true
[[ -x "$BACKUP_SCRIPT" ]] && pass "backup.sh is executable" || fail "backup.sh not executable"

# Test 2: backup.sh --dry-run works
info "Testing --dry-run..."
if bash "$BACKUP_SCRIPT" --target all --dry-run > /dev/null 2>&1; then
  pass "backup.sh --dry-run executes"
else
  fail "backup.sh --dry-run failed"
  ((FAILED++)) || true
fi

# Test 3: backup.sh --list works
info "Testing --list..."
bash "$BACKUP_SCRIPT" --list > /dev/null 2>&1 && pass "backup.sh --list works" || fail "backup.sh --list failed"

# Test 4: disaster-recovery.md exists
assert_file_exists "$PROJECT_ROOT/docs/disaster-recovery.md" "disaster-recovery.md exists" || ((FAILED++)) || true

# Test 5: backup containers
info "Testing backup containers..."
for container in duplicati restic-rest-server; do
  if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
    assert_container_running "$container" "Container: $container" || ((FAILED++)) || true
  fi
done

exit $FAILED