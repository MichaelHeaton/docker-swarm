# Traefik VLAN 5 Access Solution

## Problem

- Users on VLAN 5 (172.16.5.0/24) need to access `traefik.specterrealm.com`
- Swarm nodes currently only have IPs on VLAN 15 (management)
- Docker Swarm ingress network routes traffic, but VLAN 5 users can't reach VLAN 15 IPs
- DNS will point to `172.16.5.13`, but that IP doesn't exist on any node yet

## Solution Options

### Option 1: Add VLAN 5 IP to Swarm Manager Node (Recommended)

Add a VLAN 5 IP address to one of the Swarm manager nodes (e.g., `swarm-pi5-01`):

1. **Configure VLAN 5 interface on the node**:
   - Add `172.16.5.13/24` to `swarm-pi5-01` on VLAN 5 interface
   - This makes the node multi-homed (VLAN 15 + VLAN 5)

2. **Docker Swarm ingress will work**:
   - Traefik uses `mode: ingress` for ports 80/443
   - Ingress network routes traffic from ANY node IP to the service
   - When users on VLAN 5 access `172.16.5.13:80/443`, Swarm routes it to Traefik

3. **Update DNS**:
   - Point `traefik.specterrealm.com` to `172.16.5.13`

### Option 2: Use Existing VLAN 5 Infrastructure

If there's already a device on VLAN 5 that can proxy to the Swarm:
- Configure that device to forward traffic to Swarm manager IPs
- Point DNS to that device's VLAN 5 IP

## Implementation (Option 1)

### Step 1: Add VLAN 5 IP to Swarm Manager

On `swarm-pi5-01`, add VLAN 5 interface with IP `172.16.5.13/24`:

```bash
# Check current network config
cat /etc/netplan/*.yaml

# Add VLAN 5 interface (eth0.5) with IP 172.16.5.13/24
# This requires updating Netplan configuration
```

### Step 2: Verify Docker Swarm Ingress

Docker Swarm ingress network (`10.0.0.0/24`) automatically routes traffic:
- Traffic to `172.16.5.13:80` → Swarm ingress → Traefik service
- Traffic to `172.16.5.13:443` → Swarm ingress → Traefik service

### Step 3: Update DNS

- `traefik.specterrealm.com` → `172.16.5.13` (A record)

### Step 4: Test Access

From a device on VLAN 5:
```bash
curl -k https://traefik.specterrealm.com
# Should work!
```

## Current Status

- ✅ Traefik service is running with ingress mode
- ✅ Swarm ingress network is configured (10.0.0.0/24)
- ⚠️ Swarm nodes need VLAN 5 IPs for VLAN 5 users to access
- ⚠️ DNS needs to point to a VLAN 5 IP (e.g., 172.16.5.13)

## Next Steps

1. Add VLAN 5 interface with IP `172.16.5.13/24` to `swarm-pi5-01`
2. Update DNS: `traefik.specterrealm.com` → `172.16.5.13`
3. Test access from VLAN 5
4. Ensure Cloudflare API token is set for SSL certificates

