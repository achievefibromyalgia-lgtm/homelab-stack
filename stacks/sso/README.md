# SSO — Authentik 统一身份认证

## Overview

Authentik provides unified OIDC/SAML authentication for all Homelab Stack services.

**URL**: `https://auth.<DOMAIN>` (Port 9000)

## Services Integrated

| Service | Method | Port | Status |
|---------|--------|------|--------|
| Grafana | OIDC | 3001 | ✅ Configured |
| Gitea | OIDC | 3002 | ✅ Configured |
| Nextcloud | OIDC | 8080 | ✅ Configured |
| Outline | OIDC | 3003 | ✅ Configured |
| Portainer | OAuth | 9000 | ✅ Configured |
| Open WebUI | OIDC | 3004 | ✅ Configured |

## Quick Start

```bash
cd stacks/sso
cp .env.example .env
# Edit .env: set AUTHENTIK_PASSWORD, DOMAIN

# Start
docker compose up -d

# Wait 60s for first boot
sleep 60

# Run setup script
../../scripts/authentik-setup.sh
```

## OIDC Setup Script

```bash
# Preview what would be created
./authentik-setup.sh --dry-run

# Actually create all providers
./authentik-setup.sh
```

The script creates:
1. OIDC Provider for each service
2. Application entries in Authentik
3. Outputs Client ID + Secret for each service

## Traefik ForwardAuth

For services without native OIDC support, use ForwardAuth middleware:

```yaml
# In any service's docker-compose.yml labels:
- "traefik.http.routers.<name>.middlewares=authentik@file"
```

The `authentik@file` middleware is defined in:
`config/traefik/dynamic/middlewares.yml`

## User Groups

| Group | Access |
|-------|--------|
| `homelab-admins` | Full access to all services |
| `media-users` | Jellyfin, Sonarr, Radarr |
| `productivity-users` | Gitea, Outline, BookStack |

## Adding a New Service

1. Create OIDC provider:
```bash
./authentik-setup.sh  # Or manually via Authentik UI
```

2. Get Client ID + Secret from output

3. Add to service's `.env`:
```bash
OIDC_ISSUER=https://auth.${DOMAIN}/application/o/<slug>/
OIDC_CLIENT_ID=xxxxx
OIDC_CLIENT_SECRET=xxxxx
```

4. Configure service's auth settings to use Authentik OIDC

## Health Check

```bash
curl https://auth.${DOMAIN}/outpost.goauthentik.io/health
# Expected: {"version":"2024.8.3","cache":{"status":"ok"}}
```

## Acceptance Criteria

- [x] Authentik Web UI accessible
- [x] Admin can login
- [x] authentik-setup.sh creates providers
- [x] Grafana login via Authentik works
- [x] Gitea login via Authentik works
- [x] Nextcloud login via Authentik works
- [x] Outline login via Authentik works
- [x] ForwardAuth protects at least one non-OIDC service
- [x] User group isolation working