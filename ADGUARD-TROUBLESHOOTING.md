# AdGuard Troubleshooting Guide

## Current Issue: Connection Refused on Port 53

AdGuard container is running but DNS queries are being refused. This usually means:

1. AdGuard hasn't completed initial setup
2. AdGuard isn't listening on the interfaces
3. Firewall is blocking port 53

## Diagnostic Steps

### Step 1: Check Container Status

```bash
ssh swarm-pi5-01

# Check container is running
docker ps | grep adguard

# Check container logs
docker logs adguard

# Check if AdGuard is listening on port 53
sudo ss -tulpn | grep :53
# Or
sudo lsof -i :53
```

### Step 2: Check AdGuard Web UI

AdGuard requires initial setup via web UI:

```bash
# Access AdGuard Web UI
# From your local machine or a device on VLAN 15:
# https://172.16.15.2:3000
# Or
# https://172.16.15.13:3000 (node IP)
```

**Initial Setup Steps:**

1. Open AdGuard Web UI
2. Complete the setup wizard
3. Configure DNS settings:
   - **Listen interfaces**: Set to `0.0.0.0` (all interfaces)
   - **Upstream DNS**: Configure (e.g., `172.16.15.1` for UniFi DNS, or `1.1.1.1` for Cloudflare)
4. Save configuration

### Step 3: Verify IP Aliases

```bash
# On swarm-pi5-01
ip addr show eth0.5 | grep 172.16.5.2
ip addr show eth0.101 | grep 172.16.101.2
ip addr show eth0.15 | grep 172.16.15.2
```

### Step 4: Check Firewall

```bash
# On swarm-pi5-01
sudo ufw status
sudo ufw allow 53/udp
sudo ufw allow 53/tcp
```

### Step 5: Test from Container Itself

```bash
# Test DNS from inside the container
docker exec adguard nslookup google.com 127.0.0.1
docker exec adguard nslookup google.com 172.16.15.2
```

## Common Issues

### Issue 1: AdGuard Not Initialized

**Symptom**: Container running but no web UI accessible

**Solution**:

- Access web UI at `https://172.16.15.2:3000` or `https://172.16.15.13:3000`
- Complete initial setup wizard
- Configure DNS settings

### Issue 2: Not Listening on All Interfaces

**Symptom**: Works on one VLAN but not others

**Solution**:

- In AdGuard Web UI: Settings → DNS Settings
- Set **Listen interfaces** to `0.0.0.0` (all interfaces)
- Save and restart

### Issue 3: Firewall Blocking

**Symptom**: Connection refused from external devices

**Solution**:

```bash
sudo ufw allow 53/udp
sudo ufw allow 53/tcp
```

### Issue 4: IP Aliases Not Configured

**Symptom**: Can't reach `.2` IPs

**Solution**:

```bash
sudo ip addr add 172.16.5.2/32 dev eth0.5
sudo ip addr add 172.16.101.2/32 dev eth0.101
sudo ip addr add 172.16.15.2/32 dev eth0.15
```

## Quick Fix Commands

```bash
# On swarm-pi5-01
# 1. Check container logs
docker logs adguard | tail -50

# 2. Check if port 53 is listening
sudo ss -tulpn | grep :53

# 3. Check firewall
sudo ufw status

# 4. Restart container
docker restart adguard

# 5. Check container status
docker ps | grep adguard
docker inspect adguard | grep -A 10 NetworkSettings
```

## Next Steps

1. Access AdGuard Web UI and complete setup
2. Configure DNS settings (listen on 0.0.0.0)
3. Test DNS resolution
4. Update DHCP settings once working
