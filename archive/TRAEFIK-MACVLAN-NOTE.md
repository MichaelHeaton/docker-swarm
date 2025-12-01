# Traefik Static IP Configuration with Macvlan

## Issue

Docker Swarm **does not support macvlan networks** in service definitions. When you try to deploy a Swarm service with macvlan networks, it will fail with an error like:

```
network vlan5_macvlan is not eligible for service discovery
```

## Solutions

### Option 1: Use Host Networking (Recommended for Static IPs)

Run Traefik with `network_mode: host` and bind to specific VLAN interfaces:

```yaml
services:
  traefik:
    network_mode: host
    command:
      - --entrypoints.web.address=172.16.5.10:80
      - --entrypoints.websecure.address=172.16.5.10:443
      # ... other config
```

**Pros:**
- Direct access to VLAN interfaces
- Static IPs work correctly
- Simple configuration

**Cons:**
- Bypasses Swarm networking
- Can't use overlay networks for service discovery
- Port conflicts if multiple services use same ports

### Option 2: Use Global Mode with Macvlan (Not Recommended)

Run Traefik in global mode (one per node) with macvlan:

```yaml
services:
  traefik:
    deploy:
      mode: global
    networks:
      vlan5_macvlan:
        ipv4_address: 172.16.5.10
```

**Pros:**
- Static IPs on VLAN networks
- Can use overlay networks for service discovery

**Cons:**
- Complex configuration
- May have issues with Swarm service discovery
- Not well-tested

### Option 3: Accept Dynamic IPs (Current)

Keep overlay networks and route via Swarm ingress:

- `traefik.specterrealm.com` → Points to any Swarm node IP (172.16.15.13)
- Traefik routes traffic via overlay networks
- No static IPs on VLAN interfaces

**Pros:**
- Works with Swarm mode
- Service discovery works correctly
- Simple configuration

**Cons:**
- No static IPs on VLAN networks
- DNS points to node IP, not Traefik IP

## Recommendation

For now, **Option 3** (current approach) is the most reliable with Docker Swarm. The DNS records can point to any Swarm manager node IP, and Traefik will route traffic correctly via overlay networks.

If you specifically need static IPs on VLAN interfaces, we'll need to use **Option 1** (host networking), but this requires reconfiguring Traefik to not use Swarm service discovery.

## Current Status

- Macvlan networks created: ✅
- Traefik stack updated with DNS labels: ✅
- Static IP configuration: ⚠️ (Requires host networking or different approach)

