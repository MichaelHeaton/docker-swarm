# Final DNS Records Configuration

## Traefik IP Address

### Recommended IP for traefik.specterrealm.com

Based on the IP addressing scheme:
- **VLAN 5 (Family)**: 172.16.5.0/24
- **Static Range**: .1 - .30 (infrastructure devices)
- **DHCP Range**: .6 - .254

**Current Assignments on VLAN 5**:
- `.1`: Gateway (FW-U36)
- `.5`: NAS01 (Family IP)
- `.9`: Traefik Internal (currently in use)
- `.74`: Minecraft01

**Recommended IP**: `172.16.5.10` (available, in static range)

## Required DNS Record Updates

### 1. Traefik A Records

#### traefik.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13 (VLAN 15) ❌
- **Should be**: **172.16.5.10** (VLAN 5) ✅
- **Purpose**: Main entry point for all user-facing services
- **Access**: VLAN 5 (Family), VLAN 101 (Guest), Public Internet
- **Action**: ⚠️ **UPDATE REQUIRED**

#### traefik-mgmt.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13 (VLAN 15)
- **Should be**: 172.16.15.17 (VLAN 15) - or keep 172.16.15.13
- **Purpose**: Management/Admin access
- **Access**: VLAN 15 (Management) only
- **Action**: ✅ Verify (may need update to 172.16.15.17)

### 2. Service CNAME Records (Point to Traefik)

All user-facing services should be **CNAME records** pointing to `traefik.specterrealm.com`:

#### portainer.specterrealm.com
- **Type**: CNAME
- **Current**: A → 172.16.15.13 ❌
- **Should be**: CNAME → `traefik.specterrealm.com` ✅
- **Action**: ⚠️ **UPDATE REQUIRED**

#### blocker.specterrealm.com
- **Type**: CNAME
- **Current**: Not configured ❌
- **Should be**: CNAME → `traefik.specterrealm.com` ✅
- **Action**: ⚠️ **CREATE REQUIRED**

### 3. Management A Records (Direct Access from VLAN 15)

These are for direct management access, not for end users:

#### portainer-mgmt.specterrealm.com
- **Type**: A
- **Current**: Not configured ❌
- **Should be**: A → **172.16.15.13** (swarm-pi5-01) ✅
- **Action**: ⚠️ **CREATE REQUIRED**

#### adguard-mgmt.specterrealm.com
- **Type**: A
- **Current**: 172.16.15.13
- **Should be**: 172.16.15.13 (swarm-pi5-01) ✅
- **Action**: ✅ Verify (already correct)

## Complete DNS Record Table

| DNS Name | Type | Current | Should Be | Action |
|----------|------|---------|------------|--------|
| `traefik.specterrealm.com` | A | 172.16.15.13 | **172.16.5.10** | ⚠️ Update |
| `traefik-mgmt.specterrealm.com` | A | 172.16.15.13 | 172.16.15.13 or 172.16.15.17 | ✅ Verify |
| `portainer.specterrealm.com` | CNAME | A → 172.16.15.13 | CNAME → `traefik.specterrealm.com` | ⚠️ Update |
| `blocker.specterrealm.com` | CNAME | Not configured | CNAME → `traefik.specterrealm.com` | ⚠️ Create |
| `portainer-mgmt.specterrealm.com` | A | Not configured | **172.16.15.13** | ⚠️ Create |
| `adguard-mgmt.specterrealm.com` | A | 172.16.15.13 | 172.16.15.13 | ✅ Verify |

## Network Configuration Note

**Important**: For `traefik.specterrealm.com` to be accessible at 172.16.5.10, Traefik must be configured to bind to VLAN 5. Since Docker Swarm overlay networks don't support static IPs on VLAN interfaces, you have two options:

### Option 1: Use Swarm Ingress (Current)
- Traefik uses Swarm ingress network
- DNS points to any Swarm manager IP (172.16.15.13)
- Traffic routes via Swarm ingress to Traefik
- **Limitation**: Not directly on VLAN 5, but accessible via routing

### Option 2: Multi-homed Traefik (Future)
- Deploy Traefik as a VM on Proxmox with multiple VLAN interfaces
- Assign static IP 172.16.5.10 on VLAN 5 interface
- Assign static IP 172.16.15.17 on VLAN 15 interface
- **Benefit**: Direct access on VLAN 5, better performance

### Current Recommendation

For now, use **Option 1** (Swarm ingress):
- Update DNS: `traefik.specterrealm.com` → A → 172.16.15.13 (or any Swarm manager)
- Ensure firewall rules allow VLAN 5 → VLAN 15 traffic for Traefik
- All service CNAMEs point to `traefik.specterrealm.com`
- Traefik proxies requests from VLAN 5 users to services on VLAN 15

## Action Checklist

1. ✅ Stack files updated with correct router names
2. ⚠️ **Update DNS**: `traefik.specterrealm.com` → A → 172.16.15.13 (or 172.16.5.10 if using Option 2)
3. ⚠️ **Update DNS**: `portainer.specterrealm.com` → CNAME → `traefik.specterrealm.com`
4. ⚠️ **Create DNS**: `blocker.specterrealm.com` → CNAME → `traefik.specterrealm.com`
5. ⚠️ **Create DNS**: `portainer-mgmt.specterrealm.com` → A → 172.16.15.13
6. ✅ Verify: `adguard-mgmt.specterrealm.com` → A → 172.16.15.13
7. ⚠️ **Verify firewall**: Allow VLAN 5 → VLAN 15 traffic for Traefik (ports 80, 443)

## Testing After DNS Updates

1. Test `portainer.specterrealm.com` → Should route via Traefik
2. Test `blocker.specterrealm.com` → Should route via Traefik
3. Test `portainer-mgmt.specterrealm.com` → Should access Portainer directly
4. Test `adguard-mgmt.specterrealm.com` → Should access AdGuard directly
5. Test from VLAN 5 device → Should access services via Traefik

