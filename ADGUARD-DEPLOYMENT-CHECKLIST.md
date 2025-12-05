# AdGuard Multi-VLAN Deployment Checklist

## Current Status

**Configuration Files Updated**: ✅

- `stacks/adguard.yml` - Updated to use macvlan networks with `.2` IPs
- `stacks/create-adguard-networks.sh` - Script ready to create networks
- `stacks/dynamic/adguard-routes.yml` - Traefik routes updated

**Deployment Status**: ⏳ Not yet deployed

## Deployment Steps

### Step 1: Create Macvlan Networks

**On `swarm-pi5-01`**, run the network creation script:

```bash
# SSH to swarm-pi5-01
ssh swarm-pi5-01

# Navigate to docker-swarm directory (or copy script there)
cd /path/to/docker-swarm

# Make script executable (if not already)
chmod +x stacks/create-adguard-networks.sh

# Run the script
./stacks/create-adguard-networks.sh
```

**Expected Output:**

```
✅ AdGuard macvlan networks created successfully!

Network Summary:
  VLAN 5 (Family):    adguard-vlan5    → 172.16.5.2
  VLAN 101 (Guest):   adguard-vlan101  → 172.16.101.2
  VLAN 15 (Management): adguard-vlan15  → 172.16.15.2
```

**Verify Networks:**

```bash
docker network ls | grep adguard
docker network inspect adguard-vlan5
docker network inspect adguard-vlan101
docker network inspect adguard-vlan15
```

### Step 2: Deploy/Update AdGuard Stack

**On any Swarm manager node:**

```bash
# Deploy the updated stack
docker stack deploy -c stacks/adguard.yml adguard

# Or if stack already exists, update it:
docker stack deploy -c stacks/adguard.yml adguard --with-registry-auth
```

**Verify Deployment:**

```bash
# Check service status
docker service ls | grep adguard

# Check service details
docker service ps adguard

# Check container IPs
docker ps | grep adguard
docker inspect <adguard_container_id> | grep -A 20 Networks
```

**Expected Container IPs:**

- `172.16.5.2` on `adguard-vlan5`
- `172.16.101.2` on `adguard-vlan101`
- `172.16.15.2` on `adguard-vlan15`

### Step 3: Update DHCP DNS Settings (UniFi Controller)

**In UniFi Controller**, update DHCP settings for each VLAN:

1. **VLAN 5 (Family)**:

   - Primary DNS: `172.16.5.2`
   - Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

2. **VLAN 101 (Guest)**:

   - Primary DNS: `172.16.101.2`
   - Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

3. **VLAN 15 (Management)**:
   - Primary DNS: `172.16.15.2`
   - Secondary DNS: `172.16.15.1` (UniFi) or `1.1.1.1` (Cloudflare)

### Step 4: Update DNS Records (UniFi Controller)

**In UniFi Controller**, add/update A records:

- `blocker.specterrealm.com` → `172.16.5.2`
- `adguard-mgmt.specterrealm.com` → `172.16.15.2`

### Step 5: Configure AdGuard Web UI

1. **Access AdGuard Web UI**:

   - Via Traefik: `https://adguard-mgmt.specterrealm.com`
   - Direct: `https://172.16.15.2:3000`

2. **Verify Listen Interfaces**:
   - Go to **Settings** → **DNS Settings**
   - Verify **Listen interfaces** is set to `0.0.0.0` (all interfaces)
   - If not, set it to `0.0.0.0`

## Testing

### Test 1: Verify Container IPs

**On swarm-pi5-01:**

```bash
# Get container ID
ADGUARD_CONTAINER=$(docker ps | grep adguard | awk '{print $1}')

# Check network configuration
docker inspect $ADGUARD_CONTAINER | grep -A 30 Networks

# Should show:
# - 172.16.5.2 on adguard-vlan5
# - 172.16.101.2 on adguard-vlan101
# - 172.16.15.2 on adguard-vlan15
```

### Test 2: Test DNS Resolution from Each VLAN

**From a device on VLAN 5:**

```bash
# Test DNS resolution
nslookup google.com 172.16.5.2
dig @172.16.5.2 google.com

# Test ad-blocking
nslookup doubleclick.net 172.16.5.2
# Should return 0.0.0.0 or be blocked
```

**From a device on VLAN 101:**

```bash
# Test DNS resolution
nslookup google.com 172.16.101.2
dig @172.16.101.2 google.com

# Test ad-blocking
nslookup doubleclick.net 172.16.101.2
# Should return 0.0.0.0 or be blocked
```

**From a device on VLAN 15:**

```bash
# Test DNS resolution
nslookup google.com 172.16.15.2
dig @172.16.15.2 google.com
```

### Test 3: Test Connectivity

**From each VLAN, test connectivity to AdGuard:**

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

### Test 4: Verify AdGuard Statistics

1. **Access AdGuard Web UI**: `https://adguard-mgmt.specterrealm.com`
2. **Check Dashboard** → **Top Clients**
3. **You should see queries from**:
   - VLAN 5 devices (172.16.5.x) querying `172.16.5.2`
   - VLAN 101 devices (172.16.101.x) querying `172.16.101.2`
   - VLAN 15 devices (172.16.15.x) querying `172.16.15.2`

### Test 5: Test DHCP DNS Assignment

**On devices that get DHCP from UniFi:**

1. **Release and renew DHCP** (or reconnect to WiFi)
2. **Check DNS settings**:

   ```bash
   # On Linux/Mac
   cat /etc/resolv.conf

   # On Windows
   ipconfig /all
   ```

3. **Verify DNS is set to AdGuard IP** for the appropriate VLAN
4. **Test DNS resolution**:
   ```bash
   nslookup google.com
   # Should use AdGuard automatically
   ```

## Troubleshooting

### AdGuard Container Not Getting IPs

**Check macvlan networks:**

```bash
docker network inspect adguard-vlan5
docker network inspect adguard-vlan101
docker network inspect adguard-vlan15
```

**Check VLAN interfaces exist:**

```bash
ip addr show eth0.5
ip addr show eth0.101
ip addr show eth0.15
```

### DNS Queries Not Working

**Check AdGuard is listening:**

```bash
# On swarm-pi5-01
docker exec <adguard_container> netstat -tulpn | grep :53
```

**Check firewall rules:**

```bash
sudo ufw status
# Should allow UDP/TCP port 53 from all VLANs
```

### Traefik Not Routing to AdGuard

**Check Traefik dynamic config:**

```bash
# Verify adguard-routes.yml is loaded
docker exec <traefik_container> cat /etc/traefik/dynamic/adguard-routes.yml
```

**Check Traefik logs:**

```bash
docker service logs traefik_traefik | grep adguard
```

## Quick Status Check

Run this to check deployment status:

```bash
echo "=== AdGuard Deployment Status ==="
echo ""
echo "Networks:"
docker network ls | grep adguard || echo "  ❌ No AdGuard networks"
echo ""
echo "Service:"
docker service ls | grep adguard || echo "  ❌ AdGuard service not deployed"
echo ""
echo "Container IPs:"
ADGUARD_CONTAINER=$(docker ps | grep adguard | awk '{print $1}')
if [ -n "$ADGUARD_CONTAINER" ]; then
  docker inspect $ADGUARD_CONTAINER | grep -E "172\.16\.(5|101|15)\.2" || echo "  ❌ Container IPs not configured"
else
  echo "  ❌ AdGuard container not running"
fi
```
