# Deploy Homepage and Uptime Kuma

## Prerequisites

1. Ensure Traefik is running and accessible
2. Ensure `.env` file exists in `stacks/` directory with `CF_API_TOKEN` set

## Deployment Steps

### 1. Deploy Homepage Family

```bash
cd /path/to/docker-swarm/stacks
source .env
docker stack deploy -c homepage-family.yml homepage-family
```

### 2. Deploy Homepage Admin

```bash
docker stack deploy -c homepage-admin.yml homepage-admin
```

### 3. Deploy Uptime Kuma

```bash
docker stack deploy -c uptime-kuma.yml uptime-kuma
```

## Initial Setup

### Homepage

1. Access `https://home.specterrealm.com` (Family) or `https://admin.specterrealm.com` (Admin)
2. Homepage will create default config files in the volumes
3. Edit config files to add services:
   - Family: `homepage_family_config` volume → `/app/config/services.yaml`
   - Admin: `homepage_admin_config` volume → `/app/config/services.yaml`

### Uptime Kuma

1. Access `https://status.specterrealm.com` or `https://status-mgmt.specterrealm.com`
2. Complete initial setup wizard:
   - Create admin account
   - Set timezone
3. Add monitors for services:
   - Portainer: `https://portainer.specterrealm.com`
   - Traefik: `https://traefik.specterrealm.com`
   - Blocker: `https://blocker.specterrealm.com`
   - Homepage Family: `https://home.specterrealm.com`
   - Homepage Admin: `https://admin.specterrealm.com`
   - Status: `https://status.specterrealm.com`

## DNS Records Required

Add these DNS records in UniFi:

### CNAME Records (Point to Traefik)

- `home.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `admin.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `status.specterrealm.com` → CNAME → `traefik.specterrealm.com`

### A Records (Management Access)

- `status-mgmt.specterrealm.com` → A → 172.16.15.13

## Verifying Deployment

```bash
# Check services are running
docker service ls | grep -E "homepage|uptime"

# Check Traefik routers
curl -s http://localhost:8080/api/http/routers | jq -r '.[] | select(.name | contains("homepage") or contains("uptime")) | "\(.name) - \(.rule) - \(.status)"'
```

## Next Steps

1. Configure Homepage services list (see `homepage-config-example.md`)
2. Set up Uptime Kuma monitors for all services
3. Integrate Uptime Kuma status into Homepage widgets
4. Add new services to Homepage as they're deployed

