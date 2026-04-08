# Disaster Recovery — Homelab Stack

## Recovery Time Objective (RTO)

| Stack | Maximum Downtime | Recovery Sequence |
|-------|-----------------|-------------------|
| Base (Traefik, Portainer) | 15 min | **First** - prerequisite for all others |
| SSO (Authentik) | 30 min | **Second** - auth required by other stacks |
| Database Layer | 1 hour | **Third** - all data services depend on this |
| Network Stack | 1 hour | After DB restored |
| Storage Stack | 2 hours | After Network restored |
| Productivity Stack | 2 hours | After SSO + DB restored |
| Media Stack | 3 hours | After Storage restored |
| Home Automation | 4 hours | Last - least critical |

## Complete Recovery Checklist

### Phase 1: Fresh Server Setup

```bash
# 1. Install Docker + Docker Compose
curl -fsSL https://get.docker.com | sh
sudo apt update && sudo apt upgrade -y

# 2. Clone homelab-stack
git clone https://github.com/your-fork/homelab-stack.git
cd homelab-stack

# 3. Recreate proxy network
docker network create proxy

# 4. Set up environment
cp .env.example .env
# Edit .env with your domain, passwords, etc.

# 5. Start Base stack first
cd stacks/base && docker compose up -d
# Verify: curl -I https://traefik.$DOMAIN
```

### Phase 2: Restore Stacks in Order

```bash
# Order matters! Don't skip steps.

# 2.1 Database first
cd ../databases && docker compose up -d

# 2.2 SSO (Authentik) - required for OIDC
cd ../sso && docker compose up -d
# Wait 60s for first boot, then run setup-authentik.sh

# 2.3 Restore data volumes from backups
# Get backup ID from: ./scripts/backup.sh --list
./scripts/backup.sh --restore <backup-id>
```

### Phase 3: Verify Each Stack

```bash
# Run verification for each stack
cd stacks/base && docker compose ps   # All healthy?
docker logs traefik --tail=20          # No errors?
docker logs portainer --tail=20       # No errors?

# Check Traefik routes
curl -I https://traefik.$DOMAIN/api/ping

# Check Portainer
curl -I https://portainer.$DOMAIN
```

### Phase 4: Data Integrity Checks

```bash
# PostgreSQL
docker exec homelab-postgres pg_isready
docker exec homelab-postgres psql -U postgres -c "SELECT 1"

# Redis
docker exec homelab-redis redis-cli ping

# Check all volumes are mounted
docker volume ls | grep homelab
```

## Backup Verification

```bash
# List backups
./scripts/backup.sh --list

# Verify backup integrity
./scripts/backup.sh --verify <backup-file.tar.gz>

# Test restore on dev environment first
```

## Cron Schedule for Auto-Backup

```bash
# Edit crontab
crontab -e

# Add this line for daily 2 AM backup
0 2 * * * /path/to/homelab-stack/scripts/backup.sh --target all >> /var/log/homelab-backup.log 2>&1

# Or use systemd timer (see backup.timer)
```

## Emergency Contacts

- Traefik docs: https://doc.traefik.io/traefik/
- Portainer: https://docs.portainer.io/
- Authentik: https://docs.goauthentik.io/

## Recovery Complete?

- [ ] All containers running: `docker ps --format "table {{.Names}}\t{{.Status}}"`
- [ ] HTTPS working: `curl -I https://traefik.$DOMAIN`
- [ ] Portainer accessible
- [ ] Authentik login working
- [ ] Database connections verified
- [ ] Notification test sent via ntfy