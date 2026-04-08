# Backup & DR Stack — 3-2-1 Backup System

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| Duplicati | `lscr.io/linuxserver/duplicati:2.0.8` | Encrypted cloud backup (web UI) |
| Restic REST Server | `restic/rest-server:0.13.0` | Local backup repository |

## Quick Start

```bash
cd stacks/backup
cp .env.example .env
# Set BACKUP_TARGET, BACKUP_DIR, RESTIC_PASSWORD

# Start services
docker compose up -d

# Web UI access:
# Duplicati: https://backup.<DOMAIN>:8200
# Restic:   https://restic.<DOMAIN>:8275
```

## 3-2-1 Backup Strategy

| Rule | Implementation |
|------|----------------|
| 3 copies | Original data + local backup + cloud/offsite |
| 2 media types | Local disk (Duplicati) + S3/R2 cloud |
| 1 offsite | Cloud backup to B2/R2/S3 |

## backup.sh Script

The main backup script at `scripts/backup.sh`:

```bash
# Dry run (see what would be backed up)
./scripts/backup.sh --target all --dry-run

# Backup all stacks
./scripts/backup.sh --target all

# Backup specific stack
./scripts/backup.sh --target media

# List available backups
./scripts/backup.sh --list

# Restore from backup
./scripts/backup.sh --restore backup-20260407-120000

# Verify backup integrity
./scripts/backup.sh --verify <backup-file.tar.gz>
```

## Environment Variables

```bash
BACKUP_TARGET=local        # local, s3, b2, r2
BACKUP_DIR=/path/to/backups
RETENTION_DAYS=30
RESTIC_PASSWORD=your_password
NTFY_URL=http://ntfy:80    # For notifications
```

## Scheduled Backups

Add to crontab:
```bash
# Daily 2 AM
0 2 * * * /path/to/homelab-stack/scripts/backup.sh --target all >> /var/log/homelab-backup.log 2>&1
```

## Disaster Recovery

See `docs/disaster-recovery.md` for full recovery procedures.

Quick recovery:
```bash
# List backups
./scripts/backup.sh --list

# Restore
./scripts/backup.sh --restore <backup-id>
```