# Traefik 404 Error Fix

## Issue

`https://traefik.specterrealm.com` returns a 404 error in the browser, even though:
- ✅ DNS is correctly pointing to `172.16.5.13`
- ✅ Router is enabled
- ✅ Traefik is responding (returns redirect to `/dashboard/`)

## Root Cause

The Traefik API dashboard service (`api@internal`) serves the dashboard at `/dashboard/`, not at the root `/`. When accessing the root path, Traefik returns a redirect, but:

1. **Self-signed certificate**: Browsers block self-signed certificates, preventing the redirect from being followed
2. **Browser security**: Modern browsers show a 404 instead of following redirects when SSL verification fails

## Solution

### Option 1: Access Dashboard Directly (Immediate Fix)

Access the dashboard at the full path:
- `https://traefik.specterrealm.com/dashboard/`

This should work even with a self-signed certificate (you'll need to accept the security warning).

### Option 2: Set Cloudflare Token (Proper Fix)

Set the Cloudflare API token so Let's Encrypt can issue proper SSL certificates:

```bash
# On any Swarm manager node
docker service update --env-add "CLOUDFLARE_DNS_API_TOKEN=your-token-here" traefik_traefik
```

After setting the token:
1. Wait 2-5 minutes for certificates
2. Access `https://traefik.specterrealm.com` - it should redirect to `/dashboard/` properly
3. Or access `https://traefik.specterrealm.com/dashboard/` directly

## Current Status

- ✅ DNS: `traefik.specterrealm.com` → `172.16.5.13`
- ✅ VLAN 5 IP: Configured on `swarm-pi5-01`
- ✅ Router: Enabled and configured
- ✅ HTTP redirect: Working (redirects to HTTPS)
- ✅ HTTPS connection: Working (but self-signed cert)
- ✅ Dashboard at `/dashboard/`: Working
- ❌ Root path `/`: Redirects but browser blocks due to self-signed cert
- ❌ Cloudflare token: **EMPTY** - needs to be set

## Testing

From a device on VLAN 5:

```bash
# This should work (with -k to ignore self-signed cert)
curl -k https://traefik.specterrealm.com/dashboard/

# This redirects but browser may block
curl -k -L https://traefik.specterrealm.com/
```

## Next Steps

1. **Immediate**: Access `https://traefik.specterrealm.com/dashboard/` directly (accept security warning)
2. **Proper fix**: Set Cloudflare API token to get valid SSL certificates
3. **After certificates**: `https://traefik.specterrealm.com` will work properly

