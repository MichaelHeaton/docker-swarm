# Diagnosing Phase 1 Access Issues

## Issue: Can't Access Prowlarr/SABnzbd

You're unable to access the services even though DNS resolves correctly.

## Possible Causes

### 1. Access Control (Most Likely)

**Prowlarr and SABnzbd use `admin-allow@docker` middleware** which **excludes VLAN 5 (Family)**.

**Admin-Allow Middleware Configuration:**

- Allows: VLAN 10, 15, 20, 40 (admin VLANs)
- Blocks: VLAN 5 (Family)

**Solution**: Access from an admin VLAN:

- **VLAN 10** (Production) - if you have a device on this VLAN
- **VLAN 15** (Management) - if you have a device on this VLAN
- **VLAN 20** (Lab) - if you have a device on this VLAN

### 2. Traefik Routing Issue

**Check if Traefik is routing correctly:**

```bash
# On manager node
docker service logs traefik_traefik --tail 50 | grep -E "prowlarr|sabnzbd"

# Check if routers are registered
docker exec $(docker ps -q -f name=traefik) wget -qO- http://localhost:8080/api/http/routers | grep -E "prowlarr|sabnzbd"
```

### 3. Service Not Ready

**Check if services are actually running:**

```bash
# Check service status
docker service ls | grep -E "prowlarr|sabnzbd"

# Check if containers are running
docker ps | grep -E "prowlarr|sabnzbd"

# Check service logs
docker service logs prowlarr_prowlarr --tail 20
docker service logs sabnzbd_sabnzbd --tail 20
```

### 4. DNS Resolution Issue

**DNS resolves to `172.16.5.3` (Traefik VIP on VLAN 5):**

- This is correct for VLAN 5 access
- But admin services block VLAN 5
- You need to access from an admin VLAN

**Alternative**: Access via management IP:

- Try: `https://prowlarr.specterrealm.com` from a device on VLAN 15
- Or: Direct IP access (if configured)

## Quick Diagnostic Commands

Run these on the manager node:

```bash
# 1. Check service status
docker service ls | grep -E "prowlarr|sabnzbd"

# 2. Test from manager node (VLAN 15 - should work)
curl -k -I https://prowlarr.specterrealm.com
curl -k -I https://sabnzbd.specterrealm.com

# 3. Check Traefik routers
docker exec $(docker ps -q -f name=traefik) wget -qO- http://localhost:8080/api/http/routers | jq '.[] | select(.name | contains("prowlarr") or contains("sabnzbd"))'

# 4. Check middleware configuration
docker exec $(docker ps -q -f name=traefik) wget -qO- http://localhost:8080/api/http/middlewares | jq '.[] | select(.name | contains("admin"))'
```

## Expected Behavior

**From VLAN 5 (Family):**

- ❌ **Blocked** - Should get 403 Forbidden or connection refused
- This is **expected** - these are admin-only services

**From Admin VLANs (10, 15, 20, 40):**

- ✅ **Allowed** - Should access successfully
- This is the **intended behavior**

## Solution

**To access Prowlarr and SABnzbd:**

1. **Use a device on an admin VLAN** (VLAN 10, 15, 20, or 40)
2. **Or temporarily test from the manager node** (VLAN 15):
   ```bash
   ssh packer@swarm-pi5-01.specterrealm.com
   curl -k https://prowlarr.specterrealm.com
   ```

**Note**: These services are intentionally restricted to admin VLANs only for security. This is the correct behavior.

## If You Need Family Access

If you want to allow Family VLAN access (not recommended for admin services), you would need to:

1. Change middleware from `admin-allow@docker` to `lan-allow@file`
2. This would allow VLAN 5 access, but defeats the purpose of admin-only services

**Recommendation**: Keep admin-only access. Use an admin VLAN device to configure these services.
