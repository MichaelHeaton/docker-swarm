# DNS Records for Homepage and Uptime Kuma

## Required DNS Records

Add these DNS records in UniFi to enable access to Homepage and Uptime Kuma:

### CNAME Records (Point to Traefik)

All user-facing services should be **CNAME records** pointing to `traefik.specterrealm.com`:

1. **home.specterrealm.com**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - Purpose: Family Homepage dashboard
   - Access: Public (VLAN 5, Guest, Internet)

2. **admin.specterrealm.com**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - Purpose: Admin Homepage dashboard
   - Access: Public (VLAN 5, Guest, Internet)

3. **status.specterrealm.com**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - Purpose: Uptime Kuma status monitoring
   - Access: Public (VLAN 5, Guest, Internet)

### A Records (Management Access)

For direct management access from VLAN 15:

4. **status-mgmt.specterrealm.com**
   - Type: A
   - IP: 172.16.15.13 (or any Swarm manager IP)
   - Purpose: Direct Uptime Kuma access for management
   - Access: VLAN 15 (Management) only

## DNS Record Summary Table

| DNS Name | Type | Points To | Purpose | Access |
|----------|------|-----------|---------|--------|
| `home.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Family Homepage | Public |
| `admin.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Admin Homepage | Public |
| `status.specterrealm.com` | CNAME | `traefik.specterrealm.com` | Uptime Kuma | Public |
| `status-mgmt.specterrealm.com` | A | 172.16.15.13 | Uptime Kuma Management | VLAN 15 |

## Verification

After adding DNS records, verify access:

```bash
# Test from VLAN 5 or management network
curl -k https://home.specterrealm.com
curl -k https://admin.specterrealm.com
curl -k https://status.specterrealm.com
curl -k https://status-mgmt.specterrealm.com
```

## Next Steps

1. Add DNS records in UniFi
2. Wait for DNS propagation (usually immediate for internal DNS)
3. Access services via their DNS names
4. Complete initial setup:
   - Homepage: Configure service lists
   - Uptime Kuma: Set up monitors and status pages

