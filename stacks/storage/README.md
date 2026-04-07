# Storage Stack — Nextcloud + MinIO + FileBrowser + Syncthing

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| Nextcloud | `nextcloud:29.0.7-fpm-alpine` + `nginx:1.27-alpine` | Personal cloud (FPM + Nginx) |
| MinIO | `minio/minio:RELEASE.2024-09-22T00-33-43Z` | S3-compatible object storage |
| FileBrowser | `filebrowser/filebrowser:v2.31.1` | Lightweight file manager |
| Syncthing | `lscr.io/linuxserver/syncthing:1.27.11` | P2P file sync |

## Quick Start

```bash
cd stacks/storage

# Copy and edit environment
cp .env.example .env
# Set: DOMAIN, NEXTCLOUD_ADMIN_USER, NEXTCLOUD_PASSWORD, etc.

# Start services
docker compose up -d
```

## Configuration

### Environment Variables

```bash
DOMAIN=homelab.local
STORAGE_PATH=/data
NEXTCLOUD_ADMIN_USER=admin
NEXTCLOUD_ADMIN_PASSWORD=changeme
NEXTCLOUD_DB_PASSWORD=nextcloud_secure_pass
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=changeme-minio
```

### Nextcloud

- URL: `https://nextcloud.<DOMAIN>`
- Uses dedicated PostgreSQL + Redis (not shared)
- OIDC via Authentik supported (configure in Nextcloud admin)

### MinIO

- Console: `https://minio.<DOMAIN>` (port 9001)
- API: `https://s3.<DOMAIN>` (port 9000)
- Default bucket `buckets` created on first start
- Can serve as Nextcloud external storage

### FileBrowser

- URL: `https://files.<DOMAIN>`
- Browse `${STORAGE_PATH}` directory

### Syncthing

- URL: `https://sync.<DOMAIN>` (port 8384)
- P2P sync — connect external devices via device ID

## Service Details

### Nextcloud with dedicated DB

```
Nextcloud FPM → Nextcloud Nginx → Traefik → HTTPS
PostgreSQL 16 (dedicated)
Redis 7 (dedicated)
```

### MinIO initialization

`mc-init` container runs on startup:
```bash
mc alias set local http://minio:9000 $MINIO_USER $MINIO_PASSWORD
mc mb local/buckets --ignore-existing
```

## URLs

| Service | URL |
|---------|-----|
| Nextcloud | `https://nextcloud.<DOMAIN>` |
| MinIO Console | `https://minio.<DOMAIN>` |
| MinIO API | `https://s3.<DOMAIN>` |
| FileBrowser | `https://files.<DOMAIN>` |
| Syncthing | `https://sync.<DOMAIN>` |

## Acceptance Criteria

- [ ] Nextcloud first-run setup works
- [ ] Nextcloud Login via OIDC (Authentik) works
- [ ] MinIO Console accessible, API works
- [ ] FileBrowser browses `${STORAGE_PATH}`
- [ ] Syncthing WebUI accessible
- [ ] All services via Traefik with HTTPS