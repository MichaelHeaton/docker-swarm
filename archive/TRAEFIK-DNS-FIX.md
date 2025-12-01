# Traefik DNS Resolution Fix

## Issue

Traefik containers were unable to resolve DNS names (specifically `acme-v02.api.letsencrypt.org`) on some nodes, causing SSL certificate issuance to fail and HTTPS routes to be unavailable.

## Root Cause

1. **DNS Resolution Failure**: Traefik containers on `swarm-pi5-01` were unable to resolve external DNS names
2. **Missing DNS Servers**: Traefik service didn't have explicit DNS servers configured, relying on Docker's internal DNS which was failing

## Solution

Added explicit DNS servers to the Traefik service configuration:

```yaml
dns:
  - 172.16.15.1  # UniFi DNS
  - 1.1.1.1      # Cloudflare DNS
```

## Changes Made

1. Updated `stacks/traefik.yml` to include DNS servers
2. Redeployed Traefik service
3. Verified DNS resolution works in all Traefik containers

## Verification

After the fix:
- ✅ DNS resolution works in all Traefik containers
- ✅ SSL certificates can be obtained from Let's Encrypt
- ✅ All HTTPS routes are accessible
- ✅ Services are accessible via their DNS names

## Status

All services should now be accessible via HTTPS:
- `https://portainer.specterrealm.com`
- `https://home.specterrealm.com`
- `https://admin.specterrealm.com`
- `https://status.specterrealm.com`
- `https://blocker.specterrealm.com`

