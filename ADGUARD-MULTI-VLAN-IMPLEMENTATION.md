# AdGuard Multi-VLAN Implementation Guide

## Overview

This guide implements AdGuard Home with multi-VLAN support (VLAN 5, VLAN 101, VLAN 15) using macvlan networks. This gives AdGuard dedicated IP addresses on each VLAN, separate from the Swarm node IPs.

## IP Address Allocation

- **VLAN 5 (Family)**: `172.16.5.2` - Dedicated DNS server IP
- **VLAN 101 (Guest)**: `172.16.101.2` - Dedicated DNS server IP
- **VLAN 15 (Management)**: `172.16.15.2` - Dedicated DNS server IP

**Note**: Using `.2` on each VLAN provides consistency and avoids conflicts with:

- `.1` - Gateway IPs
- `.10` - GPU01 IPs (reserved)
- `.13-.16` - Raspberry Pi node IPs (reserved)

## Prerequisites

- ✅ AdGuard is currently running on `swarm-pi5-01`
- ✅ VLAN interfaces (`eth0.5`, `eth0.101`, `eth0.15`) must exist (created by Ansible)
- ⏳ Macvlan networks need to be created on `swarm-pi5-01`

## Step 1: Configure VLAN Interfaces on Host

### Check Current VLAN Interfaces

```bash
# SSH to swarm-pi5-01
ssh swarm-pi5-01

# Check existing VLAN interfaces
ip addr show | grep -E "eth0\.(5|15|101)"
```

### Configure VLAN 5 Interface

```bash
# Add IP address to VLAN 5 interface
sudo ip addr add 172.16.5.13/24 dev eth0.5

# Verify
ip addr show eth0.5
```

### Configure VLAN 101 Interface

```bash
# Add IP address to VLAN 101 interface
sudo ip addr add 172.16.101.13/24 dev eth0.101

# Verify
ip addr show eth0.101
```

### Make Configuration Persistent (Managed by Ansible)

The VLAN interfaces and AdGuard IP aliases are **automatically configured by Ansible**. The network role generates Netplan configurations that include:

1. **Node IP** on each VLAN (e.g., `172.16.5.13/24` for swarm-pi5-01 on VLAN 5)
2. **AdGuard IP** on VLANs 5, 101, and 15 (e.g., `172.16.5.2/32`) if the node runs AdGuard

#### Ansible Configuration

The AdGuard IPs are defined in `ansible/inventory/swarm-pi5.yml`:

```yaml
swarm_vlans:
  - id: 5
    name: family
    subnet: 172.16.5.0/24
    adguard_ip: 172.16.5.2/32
  - id: 101
    name: guest
    subnet: 172.16.101.0/24
    adguard_ip: 172.16.101.2/32
  - id: 15
    name: mgmt
    subnet: 172.16.15.0/24
    adguard_ip: 172.16.15.2/32
```

And `swarm-pi5-01` has:

```yaml
runs_adguard: true
```

#### Apply Ansible Configuration

To apply the network configuration (including AdGuard IPs):

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network
```

This will:

- Generate Netplan configs with node IPs and AdGuard IPs (where applicable)
- Apply the configuration automatically
- Make the configuration persistent across reboots

**Note**: Manual Netplan edits are not recommended as they will be overwritten by Ansible on the next run.

## Step 2: Update AdGuard Stack Configuration

### Current Configuration Issues

- Currently uses `mgmt-network` overlay network
- DNS ports use host mode (correct)
- Web UI port uses host mode (correct)
- But container is on overlay network, not host network

### Updated Configuration

Update `stacks/adguard.yml` to use host networking:

```yaml
version: "3.8"

services:
  adguard:
    image: adguard/adguardhome:latest
    network_mode: host # Use host networking for DNS
    volumes:
      - adguard_work:/opt/adguardhome/work
      - adguard_conf:/opt/adguardhome/conf
    deploy:
      replicas: 1
      placement:
        constraints:
          - node.hostname == swarm-pi5-01
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
      labels:
        - traefik.enable=true
        # Note: Traefik labels may not work with host networking
        # Web UI access via direct IP or Traefik proxy
        - traefik.http.services.adguard.loadbalancer.server.port=3000
        # Public access via Traefik on VLAN 5 (for end users)
        - traefik.http.routers.blocker.rule=Host(`blocker.specterrealm.com`)
        - traefik.http.routers.blocker.entrypoints=websecure
        - traefik.http.routers.blocker.tls.certresolver=cf
        - traefik.http.routers.blocker.middlewares=lan-allow@file
        # HTTP -> HTTPS redirect
        - traefik.http.routers.blocker-http.rule=Host(`blocker.specterrealm.com`)
        - traefik.http.routers.blocker-http.entrypoints=web
        - traefik.http.routers.blocker-http.service=noop@internal
        - traefik.http.routers.blocker-http.middlewares=redirect-to-https@file
        - traefik.http.routers.blocker-http.priority=100
        # Management access from VLAN 15
        - traefik.http.routers.adguard-mgmt.rule=Host(`adguard-mgmt.specterrealm.com`)
        - traefik.http.routers.adguard-mgmt.entrypoints=websecure
        - traefik.http.routers.adguard-mgmt.tls.certresolver=cf
        - traefik.http.routers.adguard-mgmt.middlewares=lan-allow@file
        # HTTP -> HTTPS redirect
        - traefik.http.routers.adguard-mgmt-http.rule=Host(`adguard-mgmt.specterrealm.com`)
        - traefik.http.routers.adguard-mgmt-http.entrypoints=web
        - traefik.http.routers.adguard-mgmt-http.service=noop@internal
        - traefik.http.routers.adguard-mgmt-http.middlewares=redirect-to-https@file
        - traefik.http.routers.adguard-mgmt-http.priority=100
    cap_add:
      - NET_BIND_SERVICE # Required to bind to port 53
    environment:
      - TZ=${TRAEFIK_TIMEZONE:-UTC}

volumes:
  adguard_work:
    driver: local
  adguard_conf:
    driver: local
```

**Note**: With `network_mode: host`, Traefik service discovery may not work. We may need to configure Traefik routes manually via file provider.

## Step 3: Configure AdGuard to Listen on All Interfaces

AdGuard Home, when using macvlan networks, will automatically listen on all its network interfaces. Verify in AdGuard settings:

1. Access AdGuard Web UI: `https://adguard-mgmt.specterrealm.com` or `https://172.16.15.2:3000`
2. Go to **Settings** → **DNS Settings**
3. Verify **Listen interfaces** is set to `0.0.0.0` (all interfaces)
4. If not, set it to `0.0.0.0`

AdGuard will automatically listen on:

- `172.16.5.2:53` (VLAN 5)
- `172.16.101.2:53` (VLAN 101)
- `172.16.15.2:53` (VLAN 15)

## Step 4: Update DHCP DNS Settings

### UniFi Controller Configuration

Update DHCP settings for each VLAN:

**VLAN 5 (Family):**

- Primary DNS: `172.16.5.2` (AdGuard - dedicated DNS IP)
- Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

**VLAN 101 (Guest):**

- Primary DNS: `172.16.101.2` (AdGuard - dedicated DNS IP)
- Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

**VLAN 15 (Management):**

- Primary DNS: `172.16.15.2` (AdGuard - dedicated DNS IP)
- Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

## Step 5: Update DNS Records

### UniFi DNS Records

Add/update A records:

- `blocker.specterrealm.com` → `172.16.5.2` (VLAN 5 - dedicated DNS IP)
- `blocker-guest.specterrealm.com` → `172.16.101.2` (VLAN 101 - dedicated DNS IP) (optional)
- `adguard-mgmt.specterrealm.com` → `172.16.15.2` (VLAN 15 - dedicated DNS IP)

## Step 6: Test DNS Resolution

### From VLAN 5 Device

```bash
# Test DNS resolution
nslookup google.com 172.16.5.2
dig @172.16.5.2 google.com

# Test ad-blocking
nslookup doubleclick.net 172.16.5.2
# Should return 0.0.0.0 or be blocked
```

### From VLAN 101 Device

```bash
# Test DNS resolution
nslookup google.com 172.16.101.2
dig @172.16.101.2 google.com

# Test ad-blocking
nslookup doubleclick.net 172.16.101.2
# Should return 0.0.0.0 or be blocked
```

### From VLAN 15 Device

```bash
# Test DNS resolution
nslookup google.com 172.16.15.2
dig @172.16.15.2 google.com
```

## Step 7: Verify AdGuard Statistics

1. Access AdGuard Web UI: `https://adguard-mgmt.specterrealm.com` or `https://172.16.15.2:3000`
2. Check **Dashboard** → **Top Clients**
3. You should see queries from:
   - VLAN 5 devices (172.16.5.x) querying `172.16.5.2`
   - VLAN 101 devices (172.16.101.x) querying `172.16.101.2`
   - VLAN 15 devices (172.16.15.x) querying `172.16.15.2`

## Troubleshooting

### AdGuard Not Listening on VLAN 5/101

**Check if AdGuard is listening:**

```bash
# On swarm-pi5-01
docker ps | grep adguard
docker inspect <adguard_container_id> | grep -A 10 Networks

# Should show:
# - 172.16.5.2 on adguard-vlan5
# - 172.16.101.2 on adguard-vlan101
# - 172.16.15.2 on adguard-vlan15
```

**Check macvlan networks:**

```bash
docker network inspect adguard-vlan5
docker network inspect adguard-vlan101
docker network inspect adguard-vlan15
```

**Check VLAN interfaces (parent interfaces for macvlan):**

```bash
ip addr show eth0.5
ip addr show eth0.101
ip addr show eth0.15
```

### DNS Queries Not Reaching AdGuard

**Check firewall rules:**

```bash
# On swarm-pi5-01
sudo ufw status
# Should allow UDP/TCP port 53 from all VLANs
```

**Test connectivity:**

```bash
# From VLAN 5 device
ping 172.16.5.2
telnet 172.16.5.2 53

# From VLAN 101 device
ping 172.16.101.2
telnet 172.16.101.2 53

# From VLAN 15 device
ping 172.16.15.2
telnet 172.16.15.2 53
```

### Traefik Not Routing to AdGuard

With macvlan networks, Traefik service discovery doesn't work. Traefik routes are configured via file provider:

1. Traefik dynamic config: `stacks/dynamic/adguard-routes.yml`
2. Routes point to `172.16.15.2:3000` (AdGuard management IP)

## Security Considerations

### Firewall Rules

**No additional firewall rules needed:**

- DNS (port 53) should be accessible from client VLANs
- This is standard practice for DNS services
- AdGuard doesn't expose sensitive data

### VLAN Isolation

**Acceptable for DNS services:**

- DNS is infrastructure that needs to be accessible
- Similar to gateways (172.16.x.1) being accessible
- AdGuard filtering actually improves security

### Web UI Access

**Already protected:**

- Web UI accessible via Traefik only
- Traefik enforces HTTPS and authentication
- Direct access to port 3000 can be restricted via firewall if needed

## Rollback Plan

If issues occur:

1. **Revert AdGuard stack:**

   ```bash
   docker stack deploy -c stacks/adguard.yml adguard
   ```

2. **Remove macvlan networks (if needed):**

   ```bash
   docker network rm adguard-vlan5
   docker network rm adguard-vlan101
   docker network rm adguard-vlan15
   ```

3. **Revert DHCP settings** in UniFi Controller

## Next Steps

1. ✅ Review this implementation guide
2. ⏳ Create macvlan networks on `swarm-pi5-01` (run `stacks/create-adguard-networks.sh`)
3. ✅ AdGuard stack configuration updated (uses macvlan networks)
4. ⏳ Deploy updated stack: `docker stack deploy -c stacks/adguard.yml adguard`
5. ⏳ Update DHCP DNS settings in UniFi Controller
6. ⏳ Update DNS records in UniFi Controller
7. ⏳ Test DNS resolution from all VLANs
8. ⏳ Update documentation
