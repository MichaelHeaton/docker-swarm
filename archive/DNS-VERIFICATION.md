# DNS Verification and Cleanup

## DNS Records Status (From UniFi Interface)

### ✅ Correctly Configured

1. **`portainer.specterrealm.com`**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - Status: ✅ Correct

2. **`blocker.specterrealm.com`**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - Status: ✅ Correct

3. **`adguard-mgmt.specterrealm.com`**
   - Type: A
   - IP: 172.16.15.13
   - Status: ✅ Correct

4. **`traefik-mgmt.specterrealm.com`**
   - Type: A
   - IP: 172.16.15.13
   - Status: ✅ Correct

### ⚠️ Needs Attention

1. **`traefik.specterrealm.com`** (shown as `traefik.SpecterRealm.com` in UI)
   - Type: A
   - Current IP: 172.16.15.13 (VLAN 15)
   - **Note**: Currently points to VLAN 15. For direct VLAN 5 access, this should ideally be 172.16.5.x, but since Traefik uses Swarm ingress, 172.16.15.13 works for routing. However, VLAN 5 users may need firewall rules to access this.
   - **Status**: ⚠️ Verify firewall allows VLAN 5 → VLAN 15 for Traefik

2. **`Portainer-Mgmt.SpecterRealm.com`** (capitalization and naming issue)
   - Type: A
   - IP: 172.16.15.13
   - **Issue**: Uses capital letters and dot instead of dash
   - **Should be**: `portainer-mgmt.specterrealm.com` (lowercase, dash)
   - **Status**: ⚠️ Needs cleanup (rename to lowercase with dash)

3. **`adguard.specterrealm.com`**
   - Type: CNAME
   - Points to: `traefik.specterrealm.com`
   - **Issue**: This is the old naming. We're using `blocker.specterrealm.com` for public access and `adguard-mgmt.specterrealm.com` for management.
   - **Status**: ⚠️ Consider removing (redundant with `blocker.specterrealm.com`)

## Recommended Actions

### 1. Fix Naming Convention
- **Rename**: `Portainer-Mgmt.SpecterRealm.com` → `portainer-mgmt.specterrealm.com`
  - Ensure lowercase
  - Use dash (`-mgmt`) not dot (`.mgmt`)

### 2. Clean Up Redundant Records
- **Remove**: `adguard.specterrealm.com` (CNAME)
  - We're using `blocker.specterrealm.com` for public access
  - We're using `adguard-mgmt.specterrealm.com` for management

### 3. Verify Traefik Access
- **Current**: `traefik.specterrealm.com` → 172.16.15.13 (VLAN 15)
- **Test**: Verify VLAN 5 users can access services via Traefik
- **If needed**: Add firewall rule to allow VLAN 5 → VLAN 15 for Traefik (ports 80, 443)

## Testing Checklist

After DNS updates, test the following:

1. ✅ `portainer.specterrealm.com` → Should route via Traefik
2. ✅ `blocker.specterrealm.com` → Should route via Traefik
3. ✅ `portainer-mgmt.specterrealm.com` → Should access Portainer directly
4. ✅ `adguard-mgmt.specterrealm.com` → Should access AdGuard directly
5. ⚠️ Test from VLAN 5 device → Should access services via Traefik

## Current Router Status

All routers are configured and enabled:
- `portainer@docker` - Host(`portainer.specterrealm.com`)
- `portainer-mgmt@docker` - Host(`portainer-mgmt.specterrealm.com`)
- `blocker@docker` - Host(`blocker.specterrealm.com`)
- `adguard-mgmt@docker` - Host(`adguard-mgmt.specterrealm.com`)

