# DNS Fix Required for Traefik

## Problem

You're getting a 404/timeout when accessing `http://traefik.specterrealm.com` because:

1. **DNS resolves to `172.16.5.10`** (from UniFi DNS)
2. **Traefik is NOT listening on `172.16.5.10`** - it's running on Docker Swarm overlay networks
3. **Connection times out** because nothing is listening on that IP

## Root Cause

Docker Swarm services **cannot have static IPs on VLAN interfaces**. Traefik is running on overlay networks (internal IPs like `10.0.1.x`), not on your VLAN IPs (`172.16.5.x` or `172.16.15.x`).

## Solution

Update your DNS records in UniFi to point to **Swarm manager node IPs** instead:

### Current (Not Working)
- `traefik.specterrealm.com` → A → `172.16.5.10` ❌ (nothing listening)
- `traefik-mgmt.specterrealm.com` → A → `172.16.15.17` ❌ (nothing listening)

### Fixed (Should Work)
- `traefik.specterrealm.com` → A → `172.16.15.13` ✅ (swarm-pi5-01)
- `traefik-mgmt.specterrealm.com` → A → `172.16.15.13` ✅ (swarm-pi5-01)

**Or use any Swarm manager IP:**
- `172.16.15.13` (swarm-pi5-01)
- `172.16.15.14` (swarm-pi5-02)
- `172.16.15.15` (swarm-pi5-03)

## How It Works

1. **User requests**: `http://traefik.specterrealm.com`
2. **DNS resolves**: `traefik.specterrealm.com` → `172.16.15.13` (Swarm node)
3. **Swarm ingress**: Routes traffic from node IP to Traefik service on overlay network
4. **Traefik receives**: Request and routes based on Host header
5. **Response**: Returns through Swarm ingress back to user

## Additional Issue: Docker API Version

Traefik logs show Docker API version errors:
```
client version 1.24 is too old. Minimum supported API version is 1.44
```

This is a separate issue - Traefik v3.1 requires Docker API 1.44+, but the Docker client in the container is older. This doesn't prevent routing, but service discovery may not work correctly.

## Next Steps

1. **Update DNS in UniFi** to point to `172.16.15.13` (or any Swarm manager)
2. **Test access** to `http://traefik.specterrealm.com`
3. **Fix Docker API version** (may need to update Traefik image or Docker version)

