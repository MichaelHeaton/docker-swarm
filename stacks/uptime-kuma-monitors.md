# Uptime Kuma Monitor Configuration

## Recommended Monitors

After initial setup, configure these monitors in Uptime Kuma:

### Infrastructure Services

1. **Portainer**
   - Name: `Portainer`
   - URL: `https://portainer.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Public` (if using status page)

2. **Traefik**
   - Name: `Traefik`
   - URL: `https://traefik.specterrealm.com/dashboard/`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Public`

3. **Blocker (AdGuard)**
   - Name: `Blocker`
   - URL: `https://blocker.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Public`

4. **Homepage Family**
   - Name: `Homepage Family`
   - URL: `https://home.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Public`

5. **Homepage Admin**
   - Name: `Homepage Admin`
   - URL: `https://admin.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Private` (admin only)

6. **Status (Uptime Kuma)**
   - Name: `Status`
   - URL: `https://status.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Public`

### Docker Swarm Services (Internal)

7. **Portainer Management**
   - Name: `Portainer Management`
   - URL: `https://portainer-mgmt.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Private`

8. **AdGuard Management**
   - Name: `AdGuard Management`
   - URL: `https://adguard-mgmt.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Private`

9. **Status Management**
   - Name: `Status Management`
   - URL: `https://status-mgmt.specterrealm.com`
   - Type: `HTTP(s)`
   - Interval: `60 seconds`
   - Status Page: `Private`

## Status Page Configuration

### Public Status Page

Create a public status page showing:
- Portainer
- Traefik
- Blocker
- Homepage Family
- Status

### Private Status Page (Admin)

Create a private status page showing all monitors for admin access.

## Auto-Discovery

Uptime Kuma can be configured to automatically discover services from:
- Docker Swarm (via API)
- Traefik (via API)
- Kubernetes (via API)

For automatic discovery, configure Uptime Kuma to poll:
- Traefik API: `http://traefik:8080/api/http/routers`
- Docker API: `unix:///var/run/docker.sock`

## Notification Channels

Configure notification channels for alerts:
- Email
- Discord
- Slack
- Telegram
- Webhook

## Best Practices

1. **Monitor Intervals**: Use 60 seconds for critical services, 5 minutes for less critical
2. **Status Pages**: Create separate public and private status pages
3. **Notifications**: Set up alerts for downtime > 1 minute
4. **Heartbeat**: Use heartbeat URLs for services that support it
5. **Grouping**: Group monitors by service type (Infrastructure, Applications, etc.)

