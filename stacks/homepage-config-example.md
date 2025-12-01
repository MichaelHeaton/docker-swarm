# Homepage Configuration Examples

## Auto-Discovery from Traefik

Homepage can automatically discover services from Traefik. Here's how to configure it:

### Traefik Integration

Add this to your Homepage config file (`config/services.yaml`):

```yaml
- Traefik:
    href: https://traefik.specterrealm.com
    description: Reverse proxy and load balancer
    widget:
      type: traefik
      url: http://traefik:8080/api/http/routers
      # Optional: Filter by tags or labels
      # tags:
      #   - public
```

### Docker Integration

Homepage can also discover services from Docker:

```yaml
- Docker:
    href: https://portainer.specterrealm.com
    description: Container management
    widget:
      type: docker
      url: unix:///var/run/docker.sock
      # Optional: Filter containers
      # filters:
      #   - label=traefik.enable=true
```

## Service Configuration Examples

### Basic Service Entry

```yaml
- Streaming:
    href: https://streaming.specterrealm.com
    description: Media streaming service
    icon: plex.png
```

### Service with Status

```yaml
- Portainer:
    href: https://portainer.specterrealm.com
    description: Container management UI
    icon: portainer.png
    widget:
      type: uptime-kuma
      url: https://status.specterrealm.com/api/status-page/heartbeat/portainer
```

### Service Group

```yaml
- Infrastructure:
    items:
      - Portainer:
          href: https://portainer.specterrealm.com
          description: Container management
      - Traefik:
          href: https://traefik.specterrealm.com
          description: Reverse proxy
      - Status:
          href: https://status.specterrealm.com
          description: Service status monitoring
```

## Uptime Kuma Integration

To show service status in Homepage, configure Uptime Kuma monitors and reference them:

```yaml
- Portainer:
    href: https://portainer.specterrealm.com
    description: Container management UI
    widget:
      type: uptime-kuma
      url: https://status.specterrealm.com/api/status-page/heartbeat/portainer
```

## Recommended Service List

Based on your current services:

```yaml
- Infrastructure:
    items:
      - Portainer:
          href: https://portainer.specterrealm.com
          description: Container management
      - Traefik:
          href: https://traefik.specterrealm.com
          description: Reverse proxy
      - Status:
          href: https://status.specterrealm.com
          description: Service status monitoring
      - Blocker:
          href: https://blocker.specterrealm.com
          description: DNS ad-blocking
```

