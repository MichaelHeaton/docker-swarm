# Uptime Kuma DNS Fix Deployed

## Status: ✅ Deployed

Uptime Kuma has been updated with DNS servers to fix DNS resolution issues.

## What Was Fixed

Added explicit DNS servers to Uptime Kuma configuration:
```yaml
dns:
  - 172.16.15.1  # UniFi DNS
  - 1.1.1.1      # Cloudflare DNS
```

## Deployment

Deployed using:
```bash
cd /Users/michaelheaton/Projects/HomeLab/docker-swarm/stacks
source .env
DOCKER_HOST=ssh://packer@swarm-pi5-01 docker stack deploy -c uptime-kuma.yml uptime-kuma
```

## Next Steps

1. **Wait for container restart** (1-2 minutes)
2. **Check Uptime Kuma monitors** - They should start resolving DNS and connecting
3. **Verify DNS resolution** from within the container:
   ```bash
   docker exec <uptime-kuma-container> nslookup traefik.specterrealm.com
   ```

## Monitor Configuration

If monitors are still timing out, check:

1. **Request Timeout**: Increase to 60 seconds (from 48)
2. **Accepted Status Codes**: Should be `200-299`
3. **URLs**: Use full HTTPS URLs:
   - `https://traefik.specterrealm.com/dashboard/`
   - `https://portainer.specterrealm.com`
   - `https://blocker.specterrealm.com`
   - `https://admin.specterrealm.com`
   - `https://home.specterrealm.com`

## Troubleshooting

If monitors still fail:

1. Check Uptime Kuma logs:
   ```bash
   docker service logs uptime-kuma_uptime-kuma --tail 50
   ```

2. Test DNS from container:
   ```bash
   docker exec <container> nslookup traefik.specterrealm.com
   ```

3. Test connectivity from container:
   ```bash
   docker exec <container> curl -k -H 'Host: traefik.specterrealm.com' https://172.16.5.13/dashboard/
   ```

