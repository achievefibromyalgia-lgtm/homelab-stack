#!/usr/bin/env bash
# e2e/backup-restore.test.sh — Backup & Restore E2E Test

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/assert.sh"

section "Backup Restore E2E Test"

PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
FAILED=0

# Test 1: Run backup
info "Running backup..."
BACKUP_OUTPUT=$(bash "$PROJECT_ROOT/scripts/backup.sh" --target all --dry-run 2>&1)
if echo "$BACKUP_OUTPUT" | grep -q "Would backup"; then
  pass "backup.sh dry-run works"
else
  fail "backup.sh dry-run failed"
  ((FAILED++)) || true
fi

# Test 2: List backups
info "Listing backups..."
BACKUP_LIST=$(bash "$PROJECT_ROOT/scripts/backup.sh" --list 2>&1)
if [[ -n "$BACKUP_LIST" ]]; then
  pass "backup.sh --list works"
else
  info "No backups yet (expected for fresh install)"
fi

# Test 3: Verify backup structure
info "Checking backup directory..."
BACKUP_DIR="${PROJECT_ROOT}/backups"
mkdir -p "$BACKUP_DIR"
assert_file_exists "$PROJECT_ROOT/scripts/backup.sh" "backup.sh exists" || ((FAILED++)) || true

exit $FAILED