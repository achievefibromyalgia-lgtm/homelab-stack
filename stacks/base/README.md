# Base Infrastructure Stack

The foundation of HomeLab Stack. Must be deployed **before any other stack**.

## What's Included

| Service | Version | URL | Purpose |
|---------|---------|-----|---------|
| Traefik | v3.1.6 | `traefik.<DOMAIN>` | Reverse proxy + TLS termination |
| Portainer CE | 2.21.4 | `portainer.<DOMAIN>` | Docker management UI |
| Watchtower | 1.7.1 | — | Automatic container updates |
| docker-socket-proxy | 0.2.0 | — | Secure Docker socket isolation |

## Architecture

```
Internet → [Traefik :443] → TLS termination (Let's Encrypt)
                    ↓
            [portainer.<DOMAIN>] → Portainer
            [traefik.<DOMAIN>]  → Traefik Dashboard (BasicAuth)
            [*.<DOMAIN>]        → Other stacks via 'proxy' network
```

## Quick Start

```bash
# 1. Create proxy network
docker network create proxy

# 2. Configure
cd stacks/base
cp .env.example .env
# Edit .env: set DOMAIN, ACME_EMAIL, TRAEFIK_AUTH

# 3. Prepare TLS cert storage
touch ../../config/traefik/acme.json
chmod 600 ../../config/traefik/acme.json

# 4. Generate dashboard auth
htpasswd -nb admin YOUR_PASSWORD | sed 's/$/$$/g' > .htpasswd
# Copy result to TRAEFIK_AUTH in .env

# 5. Start
docker compose up -d

# 6. Verify
curl -I https://portainer.$DOMAIN
```

## Configuration

### Environment Variables

```bash
DOMAIN=homelab.local
TZ=Asia/Singapore
ACME_EMAIL=admin@example.com
TRAEFIK_AUTH=admin:$apr1$XXXXXX$XXXXXXXXXXXXXXXXX  # htpasswd hash
WATCHTOWER_NOTIFICATION_URL=   # Optional: ntfy URL for update alerts
```

### How to Generate htpasswd

```bash
# macOS (Apache utils)
htpasswd -nb admin PASSWORD

# Docker
docker run --rm httpd:alpine htpasswd -nb admin PASSWORD

# Copy the output (including the $ escaping) to TRAEFIK_AUTH
```

## Services

### Traefik Dashboard

- URL: `https://traefik.<DOMAIN>`
- Protected by BasicAuth (credentials from `.env`)
- Shows all active routes, middleware, and services

### Portainer

- URL: `https://portainer.<DOMAIN>`
- First login: create admin account (5 min timeout)
- Access Docker socket via socket-proxy (secure)

### Watchtower

- Runs daily at 4:00 AM
- Only updates containers with `com.centurylinklabs.watchtower.enable=true`
- Notifications via ntfy (set `WATCHTOWER_NOTIFICATION_URL`)

## Prerequisites

1. Docker + Docker Compose
2. Domain pointing to server IP (for HTTPS)
3. Port 80 + 443 open
4. `proxy` network created

## Verification

```bash
# Check all services
docker compose ps

# Check Traefik health
curl -f https://traefik.$DOMAIN/api/ping

# Check Portainer
curl -I https://portainer.$DOMAIN

# View Watchtower logs
docker logs watchtower
```

## Acceptance Criteria

- [ ] `docker compose up -d` starts all 4 containers
- [ ] All containers health checks pass
- [ ] `http://<any-ip>:80` redirects to HTTPS
- [ ] Traefik dashboard accessible with auth
- [ ] Portainer accessible at `portainer.<DOMAIN>`
- [ ] Other stacks' containers discoverable via `proxy` network
- [ ] README includes DNS + cert configuration