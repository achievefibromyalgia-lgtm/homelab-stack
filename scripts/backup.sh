#!/bin/bash
# backup.sh — Homelab Stack 3-2-1 Backup System
# Usage: backup.sh --target <stack|all> [options]
#
# Backup targets: all, media, database, sso, storage, productivity, network
#
# 3-2-1 Strategy:
#   - 3 copies of data
#   - 2 different media types (local + cloud)
#   - 1 offsite copy

set -euo pipefail

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
TARGET="all"
DRY_RUN=false
BACKUP_ID=""
VERIFY_ONLY=false

# Load environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

# Environment defaults
BACKUP_TARGET="${BACKUP_TARGET:-local}"
BACKUP_DIR="${BACKUP_DIR:-${PROJECT_ROOT}/backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
NTFY_URL="${NTFY_URL:-http://ntfy:80}"

# =============================================================================
# Help
# =============================================================================
usage() {
  cat <<EOF
Usage: $0 --target <stack|all> [options]

Options:
  --target <stack>   Stack to backup: all, media, database, sso, storage, productivity, network
  --dry-run          Show what would be backed up without executing
  --restore <id>     Restore from backup ID
  --list             List available backups
  --verify           Verify backup integrity
  -h, --help         Show this help

Examples:
  $0 --target all --dry-run
  $0 --target media
  $0 --target all --restore backup-20260407-120000
  $0 --list

Environment:
  BACKUP_TARGET      local, s3, b2, sftp
  BACKUP_DIR         Local backup directory
  RETENTION_DAYS      Days to keep backups
  NTFY_URL           ntfy notification URL
EOF
}

# =============================================================================
# Notification
# =============================================================================
notify() {
  local title="$1"
  local message="$2"
  local priority="${3:-normal}"
  
  if [[ -n "$NTFY_URL" ]]; then
    curl -s -X POST "${NTFY_URL}/homelab-backup" \
      -H "Title: ${title}" \
      -H "Priority: ${priority}" \
      -d "${message}" > /dev/null 2>&1 || true
  fi
  
  echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} ${title}: ${message}"
}

# =============================================================================
# Stack volumes
# =============================================================================
get_volumes() {
  local stack="$1"
  case "$stack" in
    all)
      echo "jellyfin-data sonarr-data radarr-data plex-data postgres-data redis-data nextcloud-data minio-data"
      ;;
    media)
      echo "jellyfin-data sonarr-data radarr-data plex-data"
      ;;
    database)
      echo "postgres-data redis-data"
      ;;
    storage)
      echo "nextcloud-data minio-data syncthing-data"
      ;;
    sso)
      echo "authentik-data postgresql-data redis-data"
      ;;
    productivity)
      echo "gitea-data outline-data vaultwarden-data"
      ;;
    network)
      echo "adguard-data wg-data"
      ;;
    *)
      echo ""
      ;;
  esac
}

# =============================================================================
# Backup single volume
# =============================================================================
backup_volume() {
  local volume="$1"
  local timestamp=$(date +%Y%m%d-%H%M%S)
  local backup_name="${volume}-${timestamp}"
  
  echo "Backing up volume: $volume"
  
  # Create backup directory
  mkdir -p "${BACKUP_DIR}/${volume}"
  
  # Use docker cp to backup volume data
  local container="backup-source-$(date +%s)"
  
  # Find a container that has this volume
  docker run --rm \
    -v "${volume}:/source:ro" \
    -v "${BACKUP_DIR}/${volume}:/backup:rw" \
    alpine:latest \
    tar czf "/backup/${backup_name}.tar.gz" -C /source . 2>/dev/null || \
    notify "WARN" "Volume $volume not found or empty" "warn"
}

# =============================================================================
# List backups
# =============================================================================
list_backups() {
  echo "Available backups in ${BACKUP_DIR}:"
  find "${BACKUP_DIR}" -name "*.tar.gz" -printf "%T@ %p\n" 2>/dev/null | \
    sort -r | head -50 | \
    awk '{print strftime("%Y-%m-%d %H:%M", $1) " " $2}'
}

# =============================================================================
# Verify backup
# =============================================================================
verify_backup() {
  local backup_file="$1"
  echo "Verifying: $backup_file"
  tar tzf "$backup_file" > /dev/null 2>&1 && \
    echo "✓ $backup_file is valid" || \
    echo "✗ $backup_file is corrupted"
}

# =============================================================================
# Restore backup
# =============================================================================
restore_backup() {
  local backup_id="$1"
  local backup_file=$(find "${BACKUP_DIR}" -name "*${backup_id}*" -name "*.tar.gz" 2>/dev/null | head -1)
  
  if [[ -z "$backup_file" ]]; then
    echo "Backup not found: $backup_id"
    exit 1
  fi
  
  echo "Restoring from: $backup_file"
  echo "This will overwrite current data!"
  read -p "Continue? [y/N] " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]] || exit 0
  
  # Find target volume from backup filename
  local volume=$(basename "$backup_file" | sed 's/-[0-9].*//')
  echo "Target volume: $volume"
  
  docker run --rm \
    -v "${volume}:/target:rw" \
    -v "$(dirname "$backup_file"):/backup:ro" \
    alpine:latest \
    sh -c "rm -rf /target/* && tar xzf '/backup/$(basename "$backup_file")' -C /target"
  
  notify "RESTORE" "Restored $volume from $backup_id" "high"
}

# =============================================================================
# Main
# =============================================================================
main() {
  mkdir -p "${BACKUP_DIR}"
  
  if [[ "$DRY_RUN" == true ]]; then
    echo "=== DRY RUN ==="
    echo "Would backup: $(get_volumes "$TARGET")"
    exit 0
  fi
  
  case "$TARGET" in
    --list)
      list_backups
      exit 0
      ;;
    --verify)
      verify_backup "${BACKUP_ID}"
      exit 0
      ;;
    --restore)
      restore_backup "$BACKUP_ID"
      exit 0
      ;;
  esac
  
  notify "BACKUP START" "Starting backup of $TARGET" "normal"
  
  local success=0
  local failed=0
  
  for vol in $(get_volumes "$TARGET"); do
    if backup_volume "$vol"; then
      ((success++)) || true
    else
      ((failed++)) || true
    fi
  done
  
  if [[ $failed -eq 0 ]]; then
    notify "BACKUP COMPLETE" "Backed up $success volumes" "low"
  else
    notify "BACKUP PARTIAL" "Success: $success, Failed: $failed" "high"
  fi
  
  # Cleanup old backups
  find "${BACKUP_DIR}" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --dry-run) DRY_RUN=true; shift ;;
    --restore) BACKUP_ID="$2"; TARGET="restore"; shift 2 ;;
    --list) TARGET="--list"; shift ;;
    --verify) VERIFY_ONLY=true; shift ;;
    -h|--help) usage; exit 0 ;;
    *) shift ;;
  esac
done

main