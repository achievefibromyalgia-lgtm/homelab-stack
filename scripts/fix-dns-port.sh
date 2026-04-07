#!/bin/bash
# fix-dns-port.sh — Handle systemd-resolved DNS port conflict on port 53
# Usage: sudo ./fix-dns-port.sh [--check|--apply|--restore]

set -e

RESOLVED_CONF="/etc/systemd/resolved.conf"
BACKUP_CONF="/etc/systemd/resolved.conf.bak"

check_port() {
    echo "=== DNS Port Status ==="
    echo ""
    echo "Port 53 usage:"
    ss -tulpn | grep :53 || echo "Port 53 not in use"
    echo ""
    echo "systemd-resolved status:"
    systemctl is-active systemd-resolved 2>/dev/null && echo "Running" || echo "Not running"
}

apply_fix() {
    echo "=== Applying fix ==="
    echo ""

    # Backup resolved.conf
    if [[ ! -f "$BACKUP_CONF" ]]; then
        cp "$RESOLVED_CONF" "$BACKUP_CONF"
        echo "Backed up $RESOLVED_CONF -> $BACKUP_CONF"
    fi

    # Disable systemd-resolved stub
    sed -i 's/^#DNS=/DNS=/g' "$RESOLVED_CONF"
    sed -i 's/^#StubListener=yes/StubListener=no/g' "$RESOLVED_CONF"

    # Ensure DNS= is set to external resolver
    if ! grep -q "^DNS=1.1.1.1" "$RESOLVED_CONF"; then
        echo "DNS=1.1.1.1" >> "$RESOLVED_CONF"
    fi

    systemctl restart systemd-resolved
    echo ""
    echo "Fix applied. Check port: ss -tulpn | grep :53"
}

restore() {
    echo "=== Restoring ==="
    if [[ -f "$BACKUP_CONF" ]]; then
        cp "$BACKUP_CONF" "$RESOLVED_CONF"
        systemctl restart systemd-resolved
        echo "Restored from backup"
    else
        echo "No backup found"
    fi
}

case "${1:-}" in
    --check)
        check_port
        ;;
    --apply)
        apply_fix
        ;;
    --restore)
        restore
        ;;
    *)
        echo "Usage: sudo $0 [--check|--apply|--restore]"
        echo "  --check   Show current DNS port status"
        echo "  --apply   Disable systemd-resolved stub, free port 53"
        echo "  --restore Restore systemd-resolved to original state"
        ;;
esac