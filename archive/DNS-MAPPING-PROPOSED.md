# Proposed DNS Mapping for Traefik

## Traefik A Records (Direct IPs)

### 1. traefik.specterrealm.com
- **Type**: A
- **IP**: **172.16.5.10** (Family VLAN - available)
- **Purpose**: Main Traefik entry point for all user-facing services
- **Access**: Family VLAN (5), Guest VLAN (101), Public Internet
- **Note**: This is where all service CNAMEs will point

### 2. traefik-mgmt.specterrealm.com
- **Type**: A
- **IP**: **172.16.15.17** (Management VLAN - available)
- **Purpose**: Management/Admin access to Traefik dashboard and API
- **Access**: Management VLAN (15) only
- **Note**: Internal admin access only

## Service CNAME Records (Point to Traefik)

All user-facing services use **CNAME records** pointing to `traefik.specterrealm.com`:

| Service DNS Name | Type | Points To | Purpose |
|-----------------|------|-----------|---------|
| `portainer.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Portainer UI |
| `streaming.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Streaming stack (Plex/Jellyfin) |
| `plex.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Plex (if using brand name) |
| `secrets.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Security stack (Vault) |
| `database.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Database stack (PostgreSQL) |
| `observability.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Observability stack (Grafana) |
| `blocker.specterrealm.com` | CNAME | `traefik.specterrealm.com` | DNS stack (AdGuard) |
| `home.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Infrastructure stack (Homepage) |
| `auth.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Infrastructure stack (Teleport) |

## How It Works

1. **User requests**: `portainer.specterrealm.com`
2. **DNS resolves**: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com` → A → `172.16.5.10`
3. **Traefik receives**: Request at `172.16.5.10:80/443` with Host header `portainer.specterrealm.com`
4. **Traefik routes**: Based on Host header, routes to Portainer service in Docker Swarm
5. **Portainer responds**: Through Traefik back to user

## Traefik Multi-Homed Setup

Traefik will need:
- **172.16.5.10** on Family network (VLAN 5) - for `traefik.specterrealm.com`
- **172.16.15.17** on Management network (VLAN 15) - for `traefik-mgmt.specterrealm.com`
- Connected to overlay networks for service discovery

## Questions to Confirm

1. ✅ IP 172.16.5.10 for `traefik.specterrealm.com` - OK?
2. ✅ IP 172.16.15.17 for `traefik-mgmt.specterrealm.com` - OK?
3. ✅ All service CNAMEs point to `traefik.specterrealm.com` - Correct?
4. ❓ Should we keep `traefik-internal.specterrealm.com` or remove it?
5. ❓ Should `traefik-mgmt.specterrealm.com` also be accessible from Family VLAN, or Management only?

## Next Steps

Once confirmed:
1. Update Traefik stack to configure static IPs on VLAN interfaces
2. Update DNS-SETUP.md with correct IPs
3. Configure Traefik labels for both DNS names
4. Deploy updated stack

