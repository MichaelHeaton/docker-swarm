# DNS Cleanup Summary

## Changes Made

### 1. Updated Stack Files

#### AdGuard (`stacks/adguard.yml`)
- ✅ Added `blocker.specterrealm.com` router (public access via Traefik on VLAN 5)
- ✅ Kept `adguard-mgmt.specterrealm.com` router (management access from VLAN 15)
- ✅ Removed subdomain pattern (no more `.mgmt.specterrealm.com`)

#### Portainer (`stacks/portainer.yml`)
- ✅ Kept `portainer.specterrealm.com` router (public access via Traefik on VLAN 5)
- ✅ Added `portainer-mgmt.specterrealm.com` router (management access from VLAN 15)
- ✅ All routers properly configured with HTTP→HTTPS redirects

### 2. DNS Naming Convention

**Service Names (Public Access)**:
- Format: `{service-name}.specterrealm.com`
- Examples: `portainer.specterrealm.com`, `blocker.specterrealm.com`
- Should be: **CNAME** → `traefik.specterrealm.com`

**Management Names (VLAN 15 Only)**:
- Format: `{service-name}-mgmt.specterrealm.com`
- Examples: `portainer-mgmt.specterrealm.com`, `adguard-mgmt.specterrealm.com`
- Should be: **A record** → Service IP on VLAN 15
- **Note**: Not for end users, only for management access

### 3. Network Architecture

**Traefik (Reverse Proxy)**:
- **Primary**: `traefik.specterrealm.com` → A → `172.16.5.x` (VLAN 5)
  - Purpose: Main entry point for all user-facing services
  - Access: VLAN 5 (Family), VLAN 101 (Guest), Public Internet
  - **Status**: ⚠️ Needs to be configured/verified

- **Management**: `traefik-mgmt.specterrealm.com` → A → `172.16.15.x` (VLAN 15)
  - Purpose: Management/Admin access
  - Access: VLAN 15 (Management) only
  - **Status**: ✅ Already configured

## Required DNS Updates

### Immediate Actions Needed

1. **Update `traefik.specterrealm.com`**:
   - Current: Points to 172.16.15.13 (VLAN 15)
   - Should be: Points to 172.16.5.x (VLAN 5)
   - **Note**: Need to determine available IP in 172.16.5.x range

2. **Update `portainer.specterrealm.com`**:
   - Current: A record → 172.16.15.13
   - Should be: CNAME → `traefik.specterrealm.com`

3. **Create `blocker.specterrealm.com`**:
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`

4. **Create `portainer-mgmt.specterrealm.com`**:
   - Type: A
   - IP: 172.16.15.x (Portainer service IP on VLAN 15)

## Current Status

### Working
- ✅ Portainer routers: `portainer.specterrealm.com` and `portainer-mgmt.specterrealm.com`
- ✅ AdGuard management router: `adguard-mgmt.specterrealm.com`
- ✅ Traefik management: `traefik-mgmt.specterrealm.com`

### Pending
- ⚠️ AdGuard service needs image fix (blocker router will appear once service is running)
- ⚠️ DNS records need to be updated (see above)
- ⚠️ Traefik needs to be accessible on VLAN 5 (172.16.5.x)

## Key Principles

1. **No Subdomains**: Use dashes (`-mgmt`), not dots (`.mgmt`)
2. **Service Names**: Use generic names (`blocker`, not `adguard`)
3. **CNAME to Traefik**: All user-facing services point to `traefik.specterrealm.com`
4. **VLAN 5 Entry**: Traefik must be on VLAN 5 for end users
5. **VLAN Isolation**: VLAN 5 users can only access VLAN 5 and Internet - Traefik proxies to VLAN 15

