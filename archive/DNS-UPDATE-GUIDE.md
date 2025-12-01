# DNS Update Guide

## Traefik IP Address Selection

### VLAN 5 (Family Network) - 172.16.5.0/24

**Available IPs for Traefik** (need to verify):
- `172.16.5.10` - Suggested (if available)
- `172.16.5.9` - Currently in use (per specs)
- `172.16.5.1` - Gateway (UniFi)
- `172.16.5.5` - NAS01 (Family IP)

**Action**: Verify which IPs are available in the 172.16.5.x range and select one for `traefik.specterrealm.com`

## Required DNS Record Updates

### 1. Traefik A Records

#### traefik.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13 (VLAN 15)
- **Should be**: 172.16.5.x (VLAN 5) - **NEEDS UPDATE**
- **Purpose**: Main entry point for all user-facing services
- **Access**: VLAN 5 (Family), VLAN 101 (Guest), Public Internet

#### traefik-mgmt.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13 (VLAN 15)
- **Status**: ✅ Correct (keep as is)
- **Purpose**: Management/Admin access
- **Access**: VLAN 15 (Management) only

### 2. Service CNAME Records (Point to Traefik)

All user-facing services should be **CNAME records** pointing to `traefik.specterrealm.com`:

#### portainer.specterrealm.com
- **Type**: CNAME
- **Current**: A → 172.16.15.13
- **Should be**: CNAME → `traefik.specterrealm.com`
- **Status**: ⚠️ **NEEDS UPDATE**

#### blocker.specterrealm.com
- **Type**: CNAME
- **Current**: Not configured
- **Should be**: CNAME → `traefik.specterrealm.com`
- **Status**: ⚠️ **NEEDS CREATION**

### 3. Management A Records (Direct Access from VLAN 15)

These are for direct management access, not for end users:

#### portainer-mgmt.specterrealm.com
- **Type**: A
- **Current**: Not configured
- **Should be**: A → 172.16.15.13 (or Portainer service IP)
- **Status**: ⚠️ **NEEDS CREATION**

#### adguard-mgmt.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13
- **Status**: ✅ Already configured (verify IP is correct)

## DNS Record Summary Table

| DNS Name | Type | Current Value | Should Be | Status |
|----------|------|---------------|------------|--------|
| `traefik.specterrealm.com` | A | 172.16.15.13 | 172.16.5.x | ⚠️ Update |
| `traefik-mgmt.specterrealm.com` | A | 172.16.15.13 | 172.16.15.13 | ✅ Keep |
| `portainer.specterrealm.com` | CNAME | A → 172.16.15.13 | CNAME → `traefik.specterrealm.com` | ⚠️ Update |
| `blocker.specterrealm.com` | CNAME | Not configured | CNAME → `traefik.specterrealm.com` | ⚠️ Create |
| `portainer-mgmt.specterrealm.com` | A | Not configured | 172.16.15.13 | ⚠️ Create |
| `adguard-mgmt.specterrealm.com` | A | 172.16.15.13 | 172.16.15.13 | ✅ Verify |

## Network Architecture Reminder

### VLAN Isolation
- **VLAN 5 (Family)**: Can only access VLAN 5 and Internet. Cannot access VLAN 15.
- **VLAN 15 (Management)**: Can access all VLANs for management.
- **Traefik**: Must be accessible on VLAN 5 to proxy requests from VLAN 5 users to services on VLAN 15.

### Traffic Flow
1. User on VLAN 5 requests `portainer.specterrealm.com`
2. DNS resolves: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com` → A → `172.16.5.x`
3. Request goes to Traefik on VLAN 5 (172.16.5.x)
4. Traefik proxies request to Portainer on VLAN 15 (mgmt-network)
5. Response returned via Traefik

## Next Steps

1. ✅ Stack files updated with correct router names
2. ⚠️ Determine available IP for Traefik on VLAN 5 (172.16.5.x)
3. ⚠️ Update DNS: `traefik.specterrealm.com` → A → 172.16.5.x
4. ⚠️ Update DNS: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com`
5. ⚠️ Create DNS: `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com`
6. ⚠️ Create DNS: `portainer-mgmt.specterrealm.com` → A → 172.16.15.13
7. ⚠️ Verify Traefik is accessible on VLAN 5 (may require network/firewall configuration)

