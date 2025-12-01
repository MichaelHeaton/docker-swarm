# Traefik Static IP on Family Network (172.16.5.9)

## Issue

According to the DNS spec (`specs-homelab/reference/common-values.md`), Traefik should have:
- **Default IP**: 172.16.0.9 (VLAN 1)
- **Internal IP**: 172.16.5.9 (VLAN 5 - Family network)

However, Docker Swarm **overlay networks don't support static IP assignment** like macvlan networks do.

## Current Setup

The current Traefik stack uses **overlay networks** which provide:
- Dynamic IPs assigned by Swarm
- Internal service discovery
- Multi-homed networking across all VLANs

But overlay networks use internal IP ranges (e.g., 10.0.1.0/24) and don't directly map to your VLAN IPs (172.16.5.0/24).

## Solutions

### Option 1: Use Macvlan Network (Recommended for Static IP)

Create a macvlan network on the host and connect Traefik to it:

```bash
# On each Swarm node, create macvlan network
docker network create -d macvlan \
  --subnet=172.16.5.0/24 \
  --gateway=172.16.5.1 \
  -o parent=eth0.5 \
  vlan5_macvlan
```

Then update the Traefik stack to include the macvlan network:

```yaml
networks:
  vlan5_macvlan:
    external: true
  # ... other overlay networks

services:
  traefik:
    networks:
      vlan5_macvlan:
        ipv4_address: 172.16.5.9
      # ... other networks
```

**Limitation**: Macvlan networks don't work well with Swarm mode. You may need to run Traefik in host mode or use a different approach.

### Option 2: Use Host Networking with VLAN Interfaces

Configure Traefik to use host networking and bind to the VLAN interface:

```yaml
services:
  traefik:
    network_mode: host
    # Bind to specific interface
    command:
      - --entrypoints.web.address=172.16.5.9:80
      - --entrypoints.websecure.address=172.16.5.9:443
```

**Limitation**: Host networking bypasses Swarm networking features.

### Option 3: Accept Dynamic IPs (Current)

Keep the current overlay network setup and:
- Use `traefik.specterrealm.com` pointing to any Swarm node IP (172.16.15.13)
- Use `traefik-internal.specterrealm.com` pointing to the same IP
- Traefik will route traffic correctly via overlay networks

**Note**: This works but doesn't match the DNS spec requirement for 172.16.5.9.

## Recommendation

For now, use **Option 3** (current setup) since:
1. Overlay networks provide better Swarm integration
2. Traefik can route to services on all VLANs via overlay networks
3. The static IP requirement may not be necessary if routing works correctly

If you specifically need `traefik-internal.specterrealm.com` to resolve to 172.16.5.9, you'll need to implement Option 1 or 2, but this may require running Traefik outside of Swarm mode or using host networking.

