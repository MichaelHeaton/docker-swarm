# Uptime Kuma DNS Resolution Fix

## Issue

Uptime Kuma is showing all services as down, but the services are actually up. This is likely because Uptime Kuma cannot resolve DNS names from within its container.

## Root Cause

Uptime Kuma needs DNS servers configured to resolve `*.specterrealm.com` domain names. Without explicit DNS configuration, it may be using Docker's default DNS resolver which might not be able to resolve your internal domain names.

## Fix Applied

Added explicit DNS servers to the Uptime Kuma service configuration:

```yaml
dns:
  - 172.16.15.1  # UniFi DNS
  - 1.1.1.1      # Cloudflare DNS
```

## Deployment

Redeploy the Uptime Kuma stack:

```bash
cd /path/to/docker-swarm/stacks
source .env
docker stack deploy -c uptime-kuma.yml uptime-kuma
```

## Alternative: Use IP Addresses

If DNS resolution still doesn't work, you can configure Uptime Kuma monitors to use IP addresses directly:

- **Traefik**: `https://172.16.5.13/dashboard/` (with Host header: `traefik.specterrealm.com`)
- **Portainer**: `https://172.16.15.13:9000` (direct access)
- **Blocker**: `https://172.16.15.13:8443` (direct access)
- **Homepage Admin**: `https://172.16.15.13` (with Host header: `admin.specterrealm.com`)
- **Homepage Family**: `https://172.16.15.13` (with Host header: `home.specterrealm.com`)

However, using IPs with Host headers in Uptime Kuma may not work well. Better to fix DNS.

## Testing DNS Resolution

After redeploying, test DNS resolution from within the Uptime Kuma container:

```bash
# Find the container
docker ps | grep uptime-kuma

# Test DNS resolution
docker exec <container_id> nslookup traefik.specterrealm.com

# Test connectivity
docker exec <container_id> curl -k -H 'Host: traefik.specterrealm.com' https://172.16.5.13/dashboard/
```

## Uptime Kuma Monitor Configuration

When configuring monitors in Uptime Kuma, use:

- **URL**: `https://traefik.specterrealm.com/dashboard/`
- **Request Timeout**: Increase to 60 seconds (from 48)
- **Accepted Status Codes**: `200-299`
- **Ignore TLS/SSL error**: Unchecked (unless you have self-signed certs)

## Next Steps

1. Redeploy Uptime Kuma with DNS configuration
2. Wait for monitors to check again (every 60 seconds)
3. Verify DNS resolution from within the container
4. If still failing, check Uptime Kuma logs for specific errors

