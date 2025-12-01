# Traefik Static IP Limitation with Docker Swarm

## Issue

Docker Swarm **does not support macvlan networks** in service definitions. When you try to deploy a Swarm service with macvlan networks, Docker will reject it with an error.

## Current DNS Configuration

Your DNS records are correctly configured:
- `traefik.specterrealm.com` → A → `172.16.5.10` (Family VLAN)
- `traefik-mgmt.specterrealm.com` → A → `172.16.15.17` (Management VLAN)

However, **Traefik cannot get these static IPs** when running as a Docker Swarm service with overlay networks.

## Why This Happens

1. **Overlay networks** (used by Swarm) assign dynamic IPs from internal ranges (e.g., 10.0.1.0/24)
2. **Macvlan networks** can provide static IPs on VLAN interfaces, but Swarm services can't use them
3. **Host networking** bypasses Swarm networking entirely

## Solutions

### Option 1: Point DNS to Swarm Node IPs (Current/Recommended)

Point DNS records to any Swarm manager node IP instead:

- `traefik.specterrealm.com` → A → `172.16.15.13` (swarm-pi5-01)
- `traefik-mgmt.specterrealm.com` → A → `172.16.15.13` (swarm-pi5-01)

**How it works:**
- Traffic hits the Swarm node IP
- Swarm ingress network routes to Traefik service
- Traefik routes to backend services via overlay networks

**Pros:**
- Works with Swarm mode
- Service discovery works correctly
- Simple configuration
- No changes needed to Traefik stack

**Cons:**
- DNS doesn't point to Traefik's "real" IP
- Traffic goes through Swarm ingress

### Option 2: Use Host Networking (Requires Reconfiguration)

Run Traefik with `network_mode: host` and bind to VLAN interfaces:

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
- Static IPs work correctly
- Direct access to VLAN interfaces

**Cons:**
- Bypasses Swarm networking
- Can't use overlay networks for service discovery
- More complex configuration
- Port conflicts possible

### Option 3: Run Traefik Outside Swarm (Not Recommended)

Run Traefik as a standalone container (not a Swarm service) with macvlan networks.

**Pros:**
- Static IPs work
- Can use macvlan networks

**Cons:**
- Loses Swarm benefits (HA, scaling, etc.)
- More complex management
- Not recommended for production

## Recommendation

**Use Option 1** (current approach) - Point DNS to Swarm node IPs. This is the most reliable approach with Docker Swarm and works correctly with service discovery.

The DNS records can be updated to point to `172.16.15.13` (or any Swarm manager IP), and Traefik will route traffic correctly via overlay networks.

## Current Status

- ✅ DNS records configured in UniFi
- ✅ Traefik stack updated with DNS labels
- ✅ Macvlan networks created (for future use if needed)
- ⚠️ Static IPs on VLAN interfaces not possible with Swarm services
- ✅ Traffic routing works via Swarm ingress

