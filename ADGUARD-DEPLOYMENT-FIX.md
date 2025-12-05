# AdGuard Deployment Fix

## Issue

Docker Swarm **does not support**:

1. `network_mode: host` in stack files (ignored with warning)
2. Macvlan networks in service definitions (scope mismatch)

The AdGuard service deployed but is using overlay networking, not host networking, so it can't access the VLAN interfaces directly.

## Solution: Standalone Container

Since we need host networking and dedicated IPs, we'll run AdGuard as a **standalone container** (not a Swarm service). This allows:

- ✅ Host networking mode
- ✅ Access to all VLAN interfaces
- ✅ Dedicated `.2` IP addresses via IP aliases
- ✅ DNS port 53 binding

## Deployment Steps

### Step 1: Configure IP Aliases on swarm-pi5-01

```bash
ssh swarm-pi5-01

# Add IP aliases for AdGuard
sudo ip addr add 172.16.5.2/32 dev eth0.5
sudo ip addr add 172.16.101.2/32 dev eth0.101
sudo ip addr add 172.16.15.2/32 dev eth0.15

# Verify
ip addr show eth0.5 | grep 172.16.5.2
ip addr show eth0.101 | grep 172.16.101.2
ip addr show eth0.15 | grep 172.16.15.2
```

### Step 2: Deploy AdGuard as Standalone Container

**Option A: Use the deployment script**

```bash
# Copy script to swarm-pi5-01
scp stacks/adguard-standalone.sh packer@swarm-pi5-01:~/

# SSH and run
ssh swarm-pi5-01
chmod +x ~/adguard-standalone.sh
~/adguard-standalone.sh
```

**Option B: Manual deployment**

```bash
ssh swarm-pi5-01

# Remove Swarm service
docker service rm adguard_adguard

# Create volumes
docker volume create adguard_work
docker volume create adguard_conf

# Run container
docker run -d \
  --name adguard \
  --restart unless-stopped \
  --network host \
  --cap-add NET_BIND_SERVICE \
  -v adguard_work:/opt/adguardhome/work \
  -v adguard_conf:/opt/adguardhome/conf \
  -e TZ=UTC \
  adguard/adguardhome:latest
```

### Step 3: Verify Deployment

```bash
# Check container is running
docker ps | grep adguard

# Check it's listening on port 53
sudo netstat -tulpn | grep :53

# Test DNS from each VLAN
# From VLAN 5 device:
nslookup google.com 172.16.5.2

# From VLAN 101 device:
nslookup google.com 172.16.101.2

# From VLAN 15 device:
nslookup google.com 172.16.15.2
```

## Make IP Aliases Persistent

The IP aliases are temporary. To make them persistent, add to Netplan:

```bash
# On swarm-pi5-01
sudo nano /etc/netplan/50-vlan-5-family.yaml
```

Add the IP alias:

```yaml
network:
  version: 2
  vlans:
    eth0.5:
      id: 5
      link: eth0
      dhcp4: false
      addresses:
        - 172.16.5.2/32 # AdGuard DNS IP
      routes:
        - to: 0.0.0.0/0
          via: 172.16.5.1
```

Repeat for VLAN 101 and VLAN 15, then:

```bash
sudo netplan apply
```

## Trade-offs

### Advantages

- ✅ Host networking works (not ignored)
- ✅ Access to all VLAN interfaces
- ✅ Dedicated `.2` IP addresses
- ✅ DNS port 53 binding works correctly
- ✅ Simpler networking setup

### Disadvantages

- ⚠️ Not managed by Swarm (no automatic restart across nodes)
- ⚠️ Manual updates required (docker pull + restart)
- ⚠️ No Swarm service discovery integration
- ⚠️ Traefik routes must use file provider (already configured)

## Management

**Update AdGuard:**

```bash
docker stop adguard
docker rm adguard
docker pull adguard/adguardhome:latest
# Then run the deployment script again
```

**View Logs:**

```bash
docker logs adguard
docker logs -f adguard  # Follow logs
```

**Restart:**

```bash
docker restart adguard
```

## Status

- ✅ IP aliases configured
- ✅ Standalone container deployed
- ✅ Host networking active
- ✅ DNS listening on all VLAN interfaces
- ⏳ Update DHCP DNS settings
- ⏳ Test DNS resolution
