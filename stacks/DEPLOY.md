# Deploying Docker Swarm Stacks

## Prerequisites

1. Create `.env` file in `stacks/` directory:

   ```bash
   # Create .env file with:
   CF_API_TOKEN=your_cloudflare_api_token_here
   TRAEFIK_TIMEZONE=America/Denver
   ```

2. Source the environment variables before deploying:
   ```bash
   source stacks/.env
   ```

## Deployment Order

Deploy services in this order:

1. Traefik (reverse proxy)
2. Portainer (container management)
3. AdGuard Home (DNS ad-blocking)
4. Homepage Family & Admin (dashboards)

## Deploying Services

### 1. Traefik (Reverse Proxy)

```bash
cd /path/to/docker-swarm/stacks
source .env
docker stack deploy -c traefik.yml traefik
```

**Wait for Traefik to be fully running before deploying other services.**

### 2. Portainer (Container Management)

```bash
docker stack deploy -c portainer.yml portainer
```

### 3. AdGuard Home (DNS Ad-Blocking)

```bash
docker stack deploy -c adguard.yml adguard
```

**Note**: AdGuard is pinned to `swarm-pi5-01` and requires port 53. Ensure `systemd-resolved` is disabled on that node.

### 4. Homepage (Dashboards)

```bash
# Deploy Family Homepage
docker stack deploy -c homepage-family.yml homepage-family

# Deploy Admin Homepage
docker stack deploy -c homepage-admin.yml homepage-admin
```

## Initial Setup

### Homepage

1. Access `https://home.specterrealm.com` (Family) or `https://admin.specterrealm.com` (Admin)
2. Homepage will create default config files in the volumes
3. Copy configuration files to containers:

   ```bash
   # Copy Family config
   docker cp stacks/homepage-family-services.yaml <container-id>:/app/config/services.yaml
   docker cp stacks/homepage-family-settings.yaml <container-id>:/app/config/settings.yaml

   # Copy Admin config
   docker cp stacks/homepage-admin-services.yaml <container-id>:/app/config/services.yaml
   docker cp stacks/homepage-admin-settings.yaml <container-id>:/app/config/settings.yaml
   ```

See `homepage-config-example.md` for configuration examples.

## DNS Records Required

### CNAME Records (Point to Traefik)

- `portainer.specterrealm.com` → `traefik.specterrealm.com`
- `blocker.specterrealm.com` → `traefik.specterrealm.com`
- `home.specterrealm.com` → `traefik.specterrealm.com`
- `admin.specterrealm.com` → `traefik.specterrealm.com`
- `streaming.specterrealm.com` → `traefik.specterrealm.com`

### A Records (Direct Access)

- `traefik.specterrealm.com` → 172.16.5.13 (VLAN 5)
- `traefik-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)
- `portainer-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)
- `adguard-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)

## Updating Stacks

After making changes to stack files:

```bash
# Source environment variables
source stacks/.env

# Update specific stack
docker stack deploy -c stacks/<stack-name>.yml <stack-name>
```

## Verifying Deployment

```bash
# Check all services are running
docker service ls

# Check specific service
docker service ps <service-name>

# Check Traefik routers
curl -s http://localhost:8080/api/http/routers | jq -r '.[] | "\(.name) - \(.rule) - \(.status)"'
```

## Environment Variables

The `.env` file should contain:

- `CF_API_TOKEN`: Your Cloudflare API token for DNS challenge (required for Traefik SSL)
- `TRAEFIK_TIMEZONE`: Timezone (default: UTC)

**Note**: Docker Swarm doesn't automatically read `.env` files like docker-compose does. You must `source` the file before deploying.

## Troubleshooting

- **Services not accessible**: Check DNS records are configured correctly
- **SSL certificates not issued**: Verify `CF_API_TOKEN` is set correctly
- **Port conflicts**: Check if ports are already in use (especially port 53 for AdGuard)
- **Network issues**: Verify VLAN configuration and firewall rules

See `../SERVICES-STATUS.md` for current service status and `../DNS-ARCHITECTURE-SUMMARY.md` for DNS architecture details.
