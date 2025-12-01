# Required DNS Records Update

## Summary

Based on the DNS architecture review, the following DNS records need to be updated in UniFi/Cloudflare.

## Traefik A Records

### 1. traefik.specterrealm.com
- **Type**: A
- **IP**: `172.16.5.x` (VLAN 5 - Family network)
- **Purpose**: Main entry point for all user-facing services
- **Access**: VLAN 5 (Family), VLAN 101 (Guest), Public Internet
- **Note**: This is where all service CNAMEs will point
- **Status**: ⚠️ **NEEDS UPDATE** - Currently points to 172.16.15.13, should point to 172.16.5.x

### 2. traefik-mgmt.specterrealm.com
- **Type**: A
- **IP**: `172.16.15.x` (VLAN 15 - Management network)
- **Purpose**: Management/Admin access to Traefik dashboard
- **Access**: VLAN 15 (Management) only
- **Status**: ✅ Already configured (points to 172.16.15.13)

## Service CNAME Records (Point to Traefik)

All user-facing services should be **CNAME records** pointing to `traefik.specterrealm.com`:

### Portainer
- **Current**: `portainer.specterrealm.com` → A → 172.16.15.13
- **Should be**: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- **Status**: ⚠️ **NEEDS UPDATE**

### AdGuard (Blocker)
- **Current**: Not configured
- **Should be**: `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- **Status**: ⚠️ **NEEDS CREATION**

## Management A Records (Direct Access from VLAN 15)

These are for direct management access, not for end users:

### Portainer Management
- **Should be**: `portainer-mgmt.specterrealm.com` → A → 172.16.15.x (Portainer service IP)
- **Status**: ⚠️ **NEEDS CREATION**

### AdGuard Management
- **Current**: `adguard-mgmt.specterrealm.com` → A → 172.16.15.13
- **Status**: ✅ Already configured (but verify IP is correct)

## Important Notes

1. **Traefik on VLAN 5**: Traefik must be accessible on VLAN 5 (172.16.5.x) for end users on VLAN 5 to access services. Currently, Traefik is only accessible on VLAN 15. This may require:
   - Network configuration to allow Traefik to bind to VLAN 5 interface
   - Or routing configuration to allow VLAN 5 access to Traefik on VLAN 15
   - Or Traefik deployment with multi-homed networking

2. **VLAN Isolation**: Remember that VLAN 5 users can only access VLAN 5 and Internet. They cannot directly access VLAN 15. Traefik must proxy requests from VLAN 5 to services on VLAN 15.

3. **Service Names**: Use generic service names:
   - `blocker.specterrealm.com` (not `adguard.specterrealm.com`)
   - `portainer.specterrealm.com` (correct)

4. **Management Names**: Use dash format:
   - `portainer-mgmt.specterrealm.com` (not `portainer.mgmt.specterrealm.com`)
   - `adguard-mgmt.specterrealm.com` (correct)

## Action Items

1. ✅ Updated stack files with correct router names
2. ⚠️ Update DNS: `traefik.specterrealm.com` → A → 172.16.5.x (need to determine available IP)
3. ⚠️ Update DNS: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com`
4. ⚠️ Create DNS: `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com`
5. ⚠️ Create DNS: `portainer-mgmt.specterrealm.com` → A → 172.16.15.x
6. ⚠️ Verify Traefik is accessible on VLAN 5 (172.16.5.x)

