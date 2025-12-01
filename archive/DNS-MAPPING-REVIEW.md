# DNS Mapping Review for Traefik

## Current Understanding

Based on the DNS spec review:

### Service DNS Names (Point to Traefik)
All user-facing services use **CNAME records** pointing to Traefik:

- `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `streaming.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `plex.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `secrets.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `database.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `observability.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `home.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)
- `auth.specterrealm.com` → CNAME → `traefik.specterrealm.com` (or `traefik-internal.specterrealm.com`)

**Key Point**: Services don't point directly to their backend - they all go through Traefik, which then routes to the appropriate backend service.

### Traefik DNS Names (Your Request)

You want:

1. **traefik.specterrealm.com**
   - Type: A
   - IP: **172.16.5.x** (Family VLAN - NOT 172.16.5.9, that's in use)
   - Purpose: Main Traefik endpoint for user-facing services
   - Used by: Family VLAN devices, Guest VLAN devices, public internet

2. **traefik-mgmt.specterrealm.com**
   - Type: A
   - IP: **172.16.15.x** (Management VLAN)
   - Purpose: Management access to Traefik dashboard/API
   - Used by: Management VLAN devices, admin access

## DNS Spec Reference

From `specs-homelab/network/dns.md`:
- Line 175: `traefik.specterrealm.com` (Default VLAN)
- Line 176: `traefik-internal.specterrealm.com` (Family VLAN)

From `specs-homelab/reference/common-values.md`:
- Line 76-77: Traefik has Default IP (172.16.0.9) and Internal IP (172.16.5.9)
- Line 79-80: DNS names are `traefik.specterrealm.com` and `traefik-internal.specterrealm.com`

## Proposed Mapping (To Confirm)

### Traefik A Records

1. **traefik.specterrealm.com**
   - IP: 172.16.5.x (Family VLAN - need to find available IP)
   - Purpose: Main entry point for all user-facing services
   - Access: Family VLAN, Guest VLAN, Public Internet

2. **traefik-mgmt.specterrealm.com**
   - IP: 172.16.15.x (Management VLAN - need to find available IP)
   - Purpose: Management/Admin access to Traefik
   - Access: Management VLAN only

### Service CNAME Records

All service DNS names should point to `traefik.specterrealm.com`:

- `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `streaming.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `plex.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `secrets.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `database.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `observability.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `home.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `auth.specterrealm.com` → CNAME → `traefik.specterrealm.com`

## Questions to Confirm

1. Should we keep `traefik-internal.specterrealm.com` or replace it with `traefik.specterrealm.com`?
2. What IP should we use for `traefik.specterrealm.com` in 172.16.5.x? (172.16.5.9 is in use)
3. What IP should we use for `traefik-mgmt.specterrealm.com` in 172.16.15.x?
4. Should all service CNAMEs point to `traefik.specterrealm.com` or `traefik-internal.specterrealm.com`?

## Current IP Usage (172.16.5.x)

From `reference/common-values.md`:
- 172.16.5.1 - Gateway (UniFi)
- 172.16.5.5 - NAS01 (Family IP)
- 172.16.5.9 - Traefik (currently in use - need different IP)

Available IPs to consider: 172.16.5.10-172.16.5.254

## Current IP Usage (172.16.15.x)

From `reference/common-values.md`:
- 172.16.15.1 - Gateway (UniFi)
- 172.16.15.5 - NAS01 (Mgmt IP)
- 172.16.15.10 - GPU01 (Proxmox)
- 172.16.15.11 - NUC01 (Proxmox)
- 172.16.15.12 - NUC02 (Proxmox)
- 172.16.15.13 - swarm-pi5-01 (adblocker-pi5-01)
- 172.16.15.14 - swarm-pi5-02 (auth-pi5-01)
- 172.16.15.15 - swarm-pi5-03 (postgresql-pi5-01)
- 172.16.15.16 - swarm-pi5-04 (unassigned)

Available IPs to consider: 172.16.15.17-172.16.15.254

