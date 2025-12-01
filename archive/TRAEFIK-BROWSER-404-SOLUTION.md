# Traefik Browser 404 Error - Solution

## Issue

Browser shows "404 Not Found" when accessing `https://traefik.specterrealm.com`, even though:
- ✅ Traefik is responding (logs show 302 redirect)
- ✅ Dashboard works at `/dashboard/`
- ✅ Router is enabled and configured correctly

## Root Cause

The browser is likely:
1. **Blocking the redirect** due to self-signed SSL certificate
2. **Not following the 302 redirect** from `/` to `/dashboard/`
3. **Showing 404** instead of the certificate warning (browser behavior)

## Immediate Solution

### Access Dashboard Directly

Instead of accessing the root URL, access the dashboard directly:
- **URL**: `https://traefik.specterrealm.com/dashboard/`
- **Note**: You'll need to accept the security warning for the self-signed certificate

This should work immediately and show the Traefik dashboard.

## Proper Fix

### Set Cloudflare API Token

The self-signed certificate is the root cause. Set the Cloudflare token to get proper Let's Encrypt certificates:

```bash
# On any Swarm manager node (e.g., swarm-pi5-02)
docker service update --env-add "CLOUDFLARE_DNS_API_TOKEN=your-actual-token-here" traefik_traefik
```

After setting the token:
1. Wait 2-5 minutes for Let's Encrypt to issue certificates
2. Access `https://traefik.specterrealm.com` - it should redirect to `/dashboard/` properly
3. No more security warnings!

## Why This Happens

1. **Traefik API service** serves the dashboard at `/dashboard/`, not `/`
2. **Root path `/`** returns a 302 redirect to `/dashboard/`
3. **Self-signed certificate** causes browsers to block the redirect
4. **Browser shows 404** instead of following the blocked redirect

## Verification

From command line (which ignores cert warnings):
```bash
# Root path - shows redirect
curl -k -I https://traefik.specterrealm.com/
# Returns: HTTP/2 302 Location: /dashboard/

# Dashboard path - works
curl -k https://traefik.specterrealm.com/dashboard/
# Returns: HTML with Traefik dashboard
```

## Current Status

- ✅ DNS: `traefik.specterrealm.com` → `172.16.5.13`
- ✅ VLAN 5 IP: Configured
- ✅ Router: Enabled
- ✅ HTTP redirect: Working
- ✅ HTTPS connection: Working
- ✅ Dashboard at `/dashboard/`: **WORKING**
- ⚠️ Root path `/`: Redirects but browser blocks due to self-signed cert
- ❌ Cloudflare token: **EMPTY** - set this to fix SSL certificates

## Next Steps

1. **Now**: Access `https://traefik.specterrealm.com/dashboard/` directly
2. **Then**: Set Cloudflare API token
3. **After**: `https://traefik.specterrealm.com` will work properly

