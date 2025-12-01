# Setting Cloudflare API Token for Traefik

## Current Issue

The Cloudflare API token is **empty** in the Traefik service, which prevents SSL certificates from being obtained from Let's Encrypt. This causes:
- HTTPS to work but with self-signed certificates (browsers will show security warnings)
- Services to be inaccessible via HTTPS from browsers

## Solution

You need to set the Cloudflare API token. Here are two methods:

### Method 1: Update Service Directly (Quick Fix)

```bash
# On any Swarm manager node (e.g., swarm-pi5-02)
docker service update --env-add "CLOUDFLARE_DNS_API_TOKEN=your-actual-token-here" traefik_traefik
```

Replace `your-actual-token-here` with your actual Cloudflare API token.

### Method 2: Create .env File and Redeploy (Recommended)

1. **Create `.env` file** on a Swarm manager node:
   ```bash
   # On swarm-pi5-02 (or any manager)
   cat > ~/.env << EOF
   CF_API_TOKEN=your-actual-token-here
   TRAEFIK_TIMEZONE=UTC
   EOF
   ```

2. **Redeploy Traefik** with environment variables:
   ```bash
   # Copy traefik.yml to the server if needed
   # Then deploy:
   source ~/.env
   docker stack deploy -c traefik.yml traefik
   ```

## Verify Token is Set

After setting the token, verify it's in the containers:

```bash
docker ps --filter 'name=traefik' --format '{{.ID}}' | head -1 | xargs -I {} docker exec {} env | grep CLOUDFLARE
```

You should see:
```
CLOUDFLARE_DNS_API_TOKEN=your-token-here
```

## Wait for SSL Certificates

After setting the token:
1. Wait 2-5 minutes for Let's Encrypt to issue certificates
2. Check Traefik logs: `docker service logs traefik_traefik | grep -i acme`
3. Test: `curl -k https://traefik.specterrealm.com` (should work without self-signed cert warning)

## Current Status

- ✅ DNS: `traefik.specterrealm.com` → `172.16.5.13`
- ✅ VLAN 5 IP: Configured on `swarm-pi5-01`
- ✅ HTTP redirect: Working (redirects to HTTPS)
- ✅ HTTPS connection: Working (but using self-signed cert)
- ❌ Cloudflare token: **EMPTY** - needs to be set
- ❌ SSL certificates: Can't be obtained without token

## Next Steps

1. Set Cloudflare API token using one of the methods above
2. Wait 2-5 minutes for certificates
3. Test `https://traefik.specterrealm.com` from a browser
4. All other services should then work via HTTPS

