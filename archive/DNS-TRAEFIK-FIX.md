# Traefik DNS and SSL Certificate Fix

## Issue

1. **DNS Record Problem**: `traefik.specterrealm.com` points to `172.16.5.10`, but Traefik doesn't have a static IP on VLAN 5. It uses overlay networks and should point to a Swarm manager node IP.

2. **SSL Certificate Problem**: Cloudflare API token (`CF_API_TOKEN`) is not being passed to Traefik containers, preventing SSL certificates from being obtained.

3. **Port 8080 Access**: Traefik API on port 8080 is in host mode but may not be accessible from outside due to firewall rules.

## Root Causes

1. **DNS Record**: The DNS record for `traefik.specterrealm.com` should point to a Swarm manager IP (e.g., `172.16.15.13`) instead of a non-existent static IP (`172.16.5.10`).

2. **Environment Variable**: The `.env` file needs to be sourced when deploying the stack to pass `CF_API_TOKEN` to containers.

3. **DNS Resolution in Containers**: Some Traefik containers on certain nodes still have DNS resolution issues.

## Solution

### 1. Update DNS Record

Update the DNS record for `traefik.specterrealm.com`:
- **Current**: `172.16.5.10` (doesn't exist)
- **Should be**: `172.16.15.13` (swarm-pi5-01) or another Swarm manager IP

### 2. Redeploy Traefik with Environment Variables

Ensure the `.env` file is sourced when deploying:

```bash
cd /home/packer/docker-swarm/stacks
source .env
docker stack deploy -c traefik.yml traefik
```

### 3. Verify DNS Configuration

The Traefik service has DNS servers configured:
```yaml
dns:
  - 172.16.15.1  # UniFi DNS
  - 1.1.1.1      # Cloudflare DNS
```

### 4. Port 8080 Access

Port 8080 is exposed in host mode. If it's not accessible from outside:
- Check firewall rules on the Swarm manager nodes
- Ensure port 8080 is allowed in UFW/iptables
- Verify the port is actually listening: `netstat -tlnp | grep 8080`

## Status

After fixes:
- ✅ Traefik routers are enabled
- ✅ DNS servers are configured in containers
- ⚠️ SSL certificates need Cloudflare token to be set
- ⚠️ DNS record needs to be updated to point to a manager IP

## Next Steps

1. Update DNS record: `traefik.specterrealm.com` → `172.16.15.13` (or another manager IP)
2. Verify `.env` file has `CF_API_TOKEN` set
3. Redeploy Traefik stack with environment variables sourced
4. Wait for SSL certificates to be obtained (may take a few minutes)
5. Test access to `https://traefik.specterrealm.com`

