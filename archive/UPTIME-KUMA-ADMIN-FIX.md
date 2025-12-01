# Uptime Kuma and Admin Homepage Fixes

## Issues Identified

### 1. Uptime Kuma DNS Resolution
**Problem**: Uptime Kuma cannot resolve DNS names, causing all monitors to timeout.

**Fix**: Added explicit DNS servers to Uptime Kuma configuration:
```yaml
dns:
  - 172.16.15.1  # UniFi DNS
  - 1.1.1.1      # Cloudflare DNS
```

**Status**: ✅ Configuration updated, needs redeployment

### 2. admin.specterrealm.com SSL Certificate
**Problem**: Traefik cannot obtain SSL certificate for `admin.specterrealm.com` because `CLOUDFLARE_DNS_API_TOKEN` is not being passed correctly.

**Error in logs**:
```
Unable to obtain ACME certificate for domains "admin.specterrealm.com":
cannot get ACME client cloudflare: some credentials information are missing:
CLOUDFLARE_DNS_API_TOKEN,CLOUDFLARE_ZONE_API_TOKEN
```

**Fix**: Ensure the `.env` file has `CF_API_TOKEN` set and Traefik is deployed with it.

## Deployment Steps

### 1. Redeploy Uptime Kuma

```bash
# On your local machine
cd /Users/michaelheaton/Projects/HomeLab/docker-swarm
scp stacks/uptime-kuma.yml packer@swarm-pi5-01:~/stacks/

# On swarm-pi5-01
ssh packer@swarm-pi5-01
cd ~/stacks
source .env
docker stack deploy -c uptime-kuma.yml uptime-kuma
```

### 2. Verify Cloudflare Token

```bash
# Check if token is in .env file
ssh packer@swarm-pi5-01 "grep CF_API_TOKEN ~/stacks/.env"

# Redeploy Traefik to ensure token is passed
ssh packer@swarm-pi5-01 "cd ~/stacks && source .env && docker stack deploy -c traefik.yml traefik"
```

## Testing

### Test Uptime Kuma DNS Resolution

After redeploying, test DNS from within the container:

```bash
# Find the container
docker ps | grep uptime-kuma

# Test DNS
docker exec <container_id> nslookup traefik.specterrealm.com

# Should return: 172.16.5.13 or similar
```

### Test admin.specterrealm.com

```bash
# From your desktop
curl -k https://admin.specterrealm.com

# Should return Homepage HTML (may show cert warning initially)
```

## Uptime Kuma Monitor Configuration

When configuring monitors, use these URLs:

- **Traefik**: `https://traefik.specterrealm.com/dashboard/`
- **Portainer**: `https://portainer.specterrealm.com`
- **Blocker**: `https://blocker.specterrealm.com`
- **Homepage Admin**: `https://admin.specterrealm.com`
- **Homepage Family**: `https://home.specterrealm.com`

**Settings**:
- **Request Timeout**: 60 seconds (increase from 48)
- **Accepted Status Codes**: `200-299`
- **Ignore TLS/SSL error**: Unchecked (unless using self-signed certs)

## Next Steps

1. ✅ Update Uptime Kuma config with DNS servers
2. ⏳ Redeploy Uptime Kuma
3. ⏳ Verify Cloudflare token in Traefik
4. ⏳ Wait for SSL certificates to be issued
5. ⏳ Verify monitors start working in Uptime Kuma

