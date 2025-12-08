# Docker Swarm Cluster

Docker Swarm cluster management for 4-node Raspberry Pi 5 cluster.

## Overview

This repository contains Ansible playbooks and Docker Swarm stack definitions for setting up and managing a Docker Swarm cluster on Raspberry Pi 5 devices.

## Cluster Architecture

- **4 Raspberry Pi 5 nodes** (8GB RAM each)
- **3 Manager nodes** (swarm-pi5-01, swarm-pi5-02, swarm-pi5-03) for HA
- **1 Worker node** (swarm-pi5-04)
- **Multi-VLAN networking** support for Traefik (VLAN 5 and VLAN 15)

## Currently Deployed Services

### Infrastructure Services

1. **Traefik** - Reverse Proxy

   - Public: `https://traefik.specterrealm.com` (172.16.5.13 - VLAN 5)
   - Management: `https://traefik-mgmt.specterrealm.com` (172.16.15.13 - VLAN 15)
   - Status: ✅ Running (2 replicas, pinned to swarm-pi5-01)

2. **Portainer** - Container Management

   - Public: `https://portainer.specterrealm.com` (via Traefik)
   - Management: `https://portainer-mgmt.specterrealm.com` (172.16.15.13 - VLAN 15)
   - Status: ✅ Running (1 replica, manager nodes)

3. **AdGuard Home** - DNS Ad-Blocking
   - Public: `https://blocker.specterrealm.com` (via Traefik)
   - Management: `https://adguard-mgmt.specterrealm.com` (172.16.15.13 - VLAN 15)
   - Status: ✅ Running (1 replica, pinned to swarm-pi5-01)

### Dashboard Services

4. **Homepage Family** - Family Dashboard

   - URL: `https://home.specterrealm.com` (via Traefik)
   - Status: ✅ Running (1 replica, manager nodes)

5. **Homepage Admin** - Admin Dashboard

   - URL: `https://admin.specterrealm.com` (via Traefik)
   - Status: ✅ Running (1 replica, manager nodes)
   - Note: Uses management URLs for all services and includes built-in status monitoring

6. **Streaming (Plex)** - Media Server
   - URL: `https://streaming.specterrealm.com` (via Traefik)
   - Status: ✅ Running (VM on Proxmox, routed via Traefik)

See `SERVICES-STATUS.md` for detailed service information and DNS configuration.

## Prerequisites

- Base OS installed and hardened (via `image-factory`)
- SSH access to all nodes
- Ansible installed on control machine
- Network connectivity between nodes
- VLAN configuration on UniFi switches

## Quick Start

### 1. Base OS Setup (if not already done)

```bash
cd ../image-factory
ansible-playbook -i ansible/inventory/pi5.yml ansible/linux-playbook.yml
```

### 2. Docker Swarm Setup

```bash
cd docker-swarm
ansible-playbook ansible/playbooks/swarm-setup.yml
```

This will:

- Install Docker Engine on all nodes
- Configure network VLANs
- Initialize Swarm cluster (first manager)
- Join additional managers and workers
- Create overlay networks

### 3. Deploy Services

```bash
cd stacks
source .env  # Set CF_API_TOKEN for Traefik
docker stack deploy -c traefik.yml traefik
docker stack deploy -c portainer.yml portainer
docker stack deploy -c adguard.yml adguard
docker stack deploy -c homepage-family.yml homepage-family
docker stack deploy -c homepage-admin.yml homepage-admin
```

See `stacks/DEPLOY.md` for detailed deployment instructions.

## Project Structure

```
docker-swarm/
├── ansible/
│   ├── ansible.cfg              # Ansible configuration
│   ├── inventory/
│   │   └── swarm-pi5.yml        # Swarm cluster inventory
│   ├── playbooks/
│   │   ├── base-os.yml          # Base OS hardening (references image-factory)
│   │   └── swarm-setup.yml      # Main Swarm setup playbook
│   └── roles/
│       ├── docker/              # Docker Engine installation
│       ├── network/             # Network/VLAN configuration
│       └── swarm/               # Swarm cluster initialization
├── stacks/
│   ├── traefik.yml              # Traefik reverse proxy
│   ├── portainer.yml            # Portainer container management
│   ├── adguard.yml              # AdGuard Home DNS ad-blocking
│   ├── homepage-family.yml      # Family dashboard
│   ├── homepage-admin.yml       # Admin dashboard
│   ├── dynamic/
│   │   └── traefik-routers.yml  # Traefik dynamic configuration
│   └── DEPLOY.md                # Deployment guide
├── SERVICES-STATUS.md            # Current service status
├── DNS-ARCHITECTURE-SUMMARY.md   # DNS architecture overview
└── README.md                     # This file
```

## Inventory

The inventory file (`ansible/inventory/swarm-pi5.yml`) defines:

- **swarm_managers**: 3 manager nodes
- **swarm_workers**: 1 worker node
- Network configuration (IPs, VLANs)
- Swarm-specific variables

## Network Configuration

The cluster supports multi-VLAN networking for Traefik:

- **VLAN 5** (Family): 172.16.5.0/24
- **VLAN 10** (Production): 172.16.10.0/24
- **VLAN 15** (Mgmt): 172.16.15.0/24
- **VLAN 40** (DMZ): 172.16.40.0/24
- **VLAN 101** (Guest): 172.16.101.0/24

Traefik is configured with multi-homed networking (VLAN 5 and VLAN 15) on `swarm-pi5-01`.

## DNS Configuration

All user-facing services use CNAME records pointing to `traefik.specterrealm.com`:

- `portainer.specterrealm.com` → `traefik.specterrealm.com`
- `blocker.specterrealm.com` → `traefik.specterrealm.com`
- `home.specterrealm.com` → `traefik.specterrealm.com`
- `admin.specterrealm.com` → `traefik.specterrealm.com`
- `streaming.specterrealm.com` → `traefik.specterrealm.com`

Management access uses A records pointing directly to VLAN 15 IPs:

- `traefik-mgmt.specterrealm.com` → 172.16.15.13
- `portainer-mgmt.specterrealm.com` → 172.16.15.3
- `adguard-mgmt.specterrealm.com` → 172.16.15.2

See `DNS-ARCHITECTURE-SUMMARY.md` for complete DNS architecture details.

## Verification

After setup, verify the cluster:

```bash
# SSH to first manager
ssh packer@swarm-pi5-01

# Check Swarm status
docker info

# List nodes
docker node ls

# List services
docker service ls

# List networks
docker network ls
```

## Documentation

### Repository Documentation

- **README.md**: This file - overview and quick start
- **SERVICES-STATUS.md**: Current deployment status and DNS configuration
- **DNS-ARCHITECTURE-SUMMARY.md**: DNS naming conventions and architecture
- **DEPLOYMENT.md**: Environment variable setup (.env configuration)
- **NFS-SHARES-SUMMARY.md**: NFS mount configuration and shares

### Stack Documentation

- **stacks/DEPLOY.md**: Service deployment instructions
- **stacks/homepage-config-example.md**: Homepage configuration examples

### Infrastructure Documentation

For detailed infrastructure documentation, see:

- **specs-homelab/stacks/infrastructure.md**: Infrastructure stack documentation (Traefik, AdGuard, Homepage)
- **specs-homelab/infrastructure/docker.md**: Docker Swarm setup and configuration
- **specs-homelab/network/dns.md**: DNS architecture and naming conventions

### Historical Documentation

- **archive/**: Historical troubleshooting and fix documentation

## Dependencies

- **image-factory**: Base OS hardening roles
- **Network**: VLAN configuration on UniFi switches
- **DNS**: UniFi DNS for service DNS names
- **Cloudflare**: External DNS and SSL certificate management

## License

MIT License - see [LICENSE](LICENSE) file for details.
