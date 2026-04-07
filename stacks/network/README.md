# Network Stack — DNS, VPN, and Proxy

## Services

| Service | Image | Purpose |
|---------|-------|---------|
| AdGuard Home | `adguard/adguardhome:v0.107.52` | DNS filtering + ad blocking |
| Unbound | `mvance/unbound:1.21.1` | Local recursive DNS resolver |
| WireGuard Easy | `ghcr.io/wg-easy/wg-easy:14` | VPN with web UI |
| Cloudflare DDNS | `ghcr.io/favonia/cloudflare-ddns:1.14.0` | Dynamic DNS updater |

## Quick Start

```bash
cd stacks/network

# Copy and edit environment
cp .env.example .env
# Set DOMAIN, WG_HOST, CF_API_TOKEN, CF_ZONE, CF_RECORD

# Start services
docker compose up -d

# Run DNS port fix (requires sudo)
sudo ./scripts/fix-dns-port.sh --apply
```

## Configuration

### Environment Variables

```bash
DOMAIN=homelab.local        # Your domain
WG_HOST=vpn.example.com      # WireGuard public hostname
CF_API_TOKEN=xxx            # Cloudflare API token
CF_ZONE=example.com         # Cloudflare zone
CF_RECORD=ddns.example.com   # DDNS record
```

### AdGuard Home

- Web UI: `http://adguard.homelab.local:3080`
- DNS: `http://adguard.homelab.local:53`

Block lists to add:
```
https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
https://raw.githubusercontent.com/AdAway/adaway.github.io/master/hosts.txt
```

### WireGuard VPN

Web UI: `http://wireguard.homelab.local:51821`

Default clients get DNS pointing to `10.8.0.1` (AdGuard Home).

### Cloudflare DDNS

Requires:
- Cloudflare API token with `Zone:DNS:Edit` permission
- A pre-created A/AAAA record in Cloudflare

### DNS Port Conflict

If port 53 is already in use by systemd-resolved:

```bash
sudo ./scripts/fix-dns-port.sh --check   # Check status
sudo ./scripts/fix-dns-port.sh --apply   # Fix (disable stub listener)
sudo ./scripts/fix-dns-port.sh --restore # Restore original
```

## Router Configuration

Point your router's DNS to AdGuard Home IP:
```
DNS1: <homelab-ip>
DNS2: 1.1.1.1  # fallback
```

## Acceptance Criteria

- [ ] AdGuard Home DNS resolves, ads blocked
- [ ] WireGuard clients connect and access LAN
- [ ] Cloudflare DDNS updates IP
- [ ] fix-dns-port.sh handles systemd-resolved conflict
- [ ] README includes router DNS configuration