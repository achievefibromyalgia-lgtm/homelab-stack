# Notifications Stack

## Services

- **ntfy** v2.11.0 — Push notification server (primary)

## Quick Start

```bash
cd stacks/notifications
cp ../../config/ntfy/env .env  # edit DOMAIN in .env
docker compose up -d
```

## Configuration

Edit `config/ntfy/env` to set:
- `DOMAIN` — your domain for ntfy URL
- `NTFY_SMTP_*` — optional email notifications

## Usage

### Send notifications

```bash
# From any stack
../../scripts/notify.sh homelab-alerts "Alert" "Disk space low" high
../../scripts/notify.sh homelab-test "Test" "Hello from homelab"
```

### Traefik Integration

All other stacks should configure their webhooks to point to:
```
https://ntfy.<DOMAIN>/<topic>
```

### Example: Alertmanager

```yaml
# config/alertmanager/alertmanager.yml
receivers:
  - name: ntfy
    webhook_configs:
      - url: 'https://ntfy.<DOMAIN>/homelab-alerts'
        send_resolved: true
```

### Example: Watchtower

```bash
WATCHTOWER_NOTIFICATION_URL=http://ntfy:80/<topic>
WATCHTOWER_NOTIFICATION_TYPE=webhook
```

## Health Check

```bash
curl http://localhost:8075/health
# Expected: {"version":"2.11.0"}
```

## Topics

| Topic | Purpose |
|-------|---------|
| `homelab-alerts` | System alerts (Alertmanager) |
| `homelab-test` | Testing notifications |
| `watchtower` | Container update alerts |

Mobile app: install ntfy and subscribe to topics above.