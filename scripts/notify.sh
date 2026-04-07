#!/bin/bash
# notify.sh — Unified notification script for HomeLab Stack
# Usage: notify.sh <topic> <title> <message> [priority]

TOPIC="${1:-homelab}"
TITLE="${2:-Notification}"
MESSAGE="${3:-}"
PRIORITY="${4:-normal}"

if [[ -z "$MESSAGE" ]]; then
  echo "Usage: notify.sh <topic> <title> <message> [priority]"
  exit 1
fi

NTFY_URL="${NTFY_URL:-http://localhost:8075}"

curl -s -X POST "${NTFY_URL}/${TOPIC}" \
  -H "Title: ${TITLE}" \
  -H "Priority: ${PRIORITY}" \
  -d "${MESSAGE}" > /dev/null 2>&1

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Sent: ${TITLE} -> ${TOPIC}"