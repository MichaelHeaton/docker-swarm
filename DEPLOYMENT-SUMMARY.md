# Docker Swarm Deployment Summary

**Last Updated**: 2025-12-01

## Overview

Docker Swarm cluster successfully deployed on 4-node Raspberry Pi 5 cluster with multi-VLAN networking support.

## Cluster Status

- **Nodes**: 4 Raspberry Pi 5 nodes (8GB RAM each)
- **Managers**: swarm-pi5-01, swarm-pi5-02, swarm-pi5-03
- **Workers**: swarm-pi5-04
- **Status**: ✅ Operational

## Deployed Services

### Infrastructure Services

1. **Traefik** (Reverse Proxy)
   - Version: v2.11
   - Replicas: 2 (pinned to swarm-pi5-01)
   - Networks: Multi-homed (VLAN 5: 172.16.5.13, VLAN 15: 172.16.15.13)
   - Public: `https://traefik.specterrealm.com`
   - Management: `https://traefik-mgmt.specterrealm.com`

2. **Portainer** (Container Management)
   - Replicas: 1 (manager nodes)
   - Public: `https://portainer.specterrealm.com`
   - Management: `https://portainer-mgmt.specterrealm.com`

3. **AdGuard Home** (DNS Ad-Blocking)
   - Replicas: 1 (pinned to swarm-pi5-01)
   - Public: `https://blocker.specterrealm.com`
   - Management: `https://adguard-mgmt.specterrealm.com`
   - DNS Ports: 53 UDP/TCP (host mode)

### Dashboard Services

4. **Homepage Family** (Family Dashboard)
   - Replicas: 1 (manager nodes)
   - URL: `https://home.specterrealm.com`
   - Configuration: `stacks/homepage-family-services.yaml`

5. **Homepage Admin** (Admin Dashboard)
   - Replicas: 1 (manager nodes)
   - URL: `https://admin.specterrealm.com`
   - Configuration: `stacks/homepage-admin-services.yaml`
   - Note: Uses management URLs for all services

6. **Uptime Kuma** (Status Monitoring)
   - Replicas: 1 (pinned to swarm-pi5-01)
   - Public: `https://status.specterrealm.com`
   - Management: `https://status-mgmt.specterrealm.com`
   - Note: Monitors use management URLs for VLAN 15 access

## DNS Configuration

### CNAME Records (Point to Traefik)
- `portainer.specterrealm.com` → `traefik.specterrealm.com`
- `blocker.specterrealm.com` → `traefik.specterrealm.com`
- `home.specterrealm.com` → `traefik.specterrealm.com`
- `admin.specterrealm.com` → `traefik.specterrealm.com`
- `status.specterrealm.com` → `traefik.specterrealm.com`
- `streaming.specterrealm.com` → `traefik.specterrealm.com`

### A Records (Direct Access)
- `traefik.specterrealm.com` → 172.16.5.13 (VLAN 5)
- `traefik-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)
- `portainer-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)
- `adguard-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)
- `status-mgmt.specterrealm.com` → 172.16.15.13 (VLAN 15)

## Network Architecture

- **VLAN 5 (Family)**: 172.16.5.0/24 - Public-facing services
- **VLAN 15 (Management)**: 172.16.15.0/24 - Management access
- **Traefik**: Multi-homed on both VLANs (swarm-pi5-01)
- **Service Isolation**: Services on VLAN 15, accessible via Traefik from VLAN 5

## Key Configuration Files

- Stack definitions: `stacks/*.yml`
- Homepage configs: `stacks/homepage-*-services.yaml`, `stacks/homepage-*-settings.yaml`
- Traefik dynamic config: `stacks/dynamic/traefik-routers.yml`
- Environment: `stacks/.env` (gitignored, contains `CF_API_TOKEN`)

## Deployment Commands

```bash
cd stacks
source .env
docker stack deploy -c traefik.yml traefik
docker stack deploy -c portainer.yml portainer
docker stack deploy -c adguard.yml adguard
docker stack deploy -c homepage-family.yml homepage-family
docker stack deploy -c homepage-admin.yml homepage-admin
docker stack deploy -c uptime-kuma.yml uptime-kuma
```

## References

- **Service Status**: `SERVICES-STATUS.md`
- **DNS Architecture**: `DNS-ARCHITECTURE-SUMMARY.md`
- **Deployment Guide**: `stacks/DEPLOY.md`
- **Main README**: `README.md`

