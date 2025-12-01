# Homepage Admin and Uptime Kuma Setup

## ✅ Status: Deployed and Running

Both services are already deployed and accessible via Traefik.

## Services

### Homepage Admin
- **URL**: `https://admin.specterrealm.com`
- **Stack**: `homepage-admin`
- **Status**: ✅ Running (1/1 replicas)
- **Volume**: `homepage_admin_config` (config files)
- **Volume**: `homepage_admin_icons` (custom icons)

### Uptime Kuma
- **Public URL**: `https://status.specterrealm.com`
- **Management URL**: `https://status-mgmt.specterrealm.com`
- **Stack**: `uptime-kuma`
- **Status**: ✅ Running (1/1 replicas)
- **Volume**: `uptime_kuma_data` (database and config)

## Initial Configuration

### Homepage Admin

1. **Access the dashboard**:
   ```bash
   # From your desktop on VLAN 5
   curl -k https://admin.specterrealm.com
   ```

2. **Edit configuration**:
   The config files are stored in the `homepage_admin_config` volume. To edit:
   ```bash
   # Find the container
   docker ps | grep homepage-admin

   # Copy config files to local machine (if needed)
   docker cp <container_id>:/app/config/config.yaml ./homepage-admin-config.yaml
   ```

3. **Add services**:
   Edit the config files to add your services. See `stacks/homepage-config-example.md` for examples.

4. **Auto-discovery**:
   Homepage can auto-discover Docker services. Ensure the Docker socket is mounted (already configured).

### Uptime Kuma

1. **Access the dashboard**:
   ```bash
   # From your desktop on VLAN 5
   curl -k https://status.specterrealm.com
   ```

2. **Initial setup**:
   - First access will show a setup wizard
   - Create an admin account
   - Set timezone
   - Configure notification channels (optional)

3. **Add monitors**:
   Add monitors for your services:
   - **Portainer**: `https://portainer.specterrealm.com`
   - **Traefik**: `https://traefik.specterrealm.com/dashboard/`
   - **Blocker (AdGuard)**: `https://blocker.specterrealm.com`
   - **Homepage Family**: `https://home.specterrealm.com`
   - **Homepage Admin**: `https://admin.specterrealm.com`
   - **Status (Uptime Kuma)**: `https://status.specterrealm.com`

## DNS Records

Ensure these DNS records are configured:

### CNAME Records (Point to Traefik)
- `admin.specterrealm.com` → CNAME → `traefik.specterrealm.com`
- `status.specterrealm.com` → CNAME → `traefik.specterrealm.com`

### A Records (Management Access)
- `status-mgmt.specterrealm.com` → A → `172.16.15.13`

## Verification

```bash
# Check services are running
docker service ls | grep -E "homepage-admin|uptime-kuma"

# Check Traefik routers
curl -s http://localhost:8080/api/http/routers | jq -r '.[] | select(.name | contains("homepage-admin") or contains("uptime-kuma")) | "\(.name) - \(.rule) - \(.status)"'
```

## Next Steps

1. ✅ **Deploy services** - DONE
2. ⏳ **Configure Homepage** - Add services to config
3. ⏳ **Set up Uptime Kuma** - Complete initial setup and add monitors
4. ⏳ **Verify DNS** - Ensure DNS records are correct
5. ⏳ **Test access** - Verify both services are accessible from VLAN 5

## Troubleshooting

### Homepage not loading
- Check Traefik logs: `docker service logs traefik_traefik`
- Verify DNS: `nslookup admin.specterrealm.com`
- Check service status: `docker service ps homepage-admin_homepage-admin`

### Uptime Kuma not loading
- Check Traefik logs: `docker service logs traefik_traefik`
- Verify DNS: `nslookup status.specterrealm.com`
- Check service status: `docker service ps uptime-kuma_uptime-kuma`
- Check Uptime Kuma logs: `docker service logs uptime-kuma_uptime-kuma`

