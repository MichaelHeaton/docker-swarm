# Traefik Desktop Access Troubleshooting

## Issues Reported

1. `http://172.16.5.13:8080` not working from desktop
2. `https://traefik.specterrealm.com/dashboard/` not working from desktop

## Fixes Applied

### 1. Constrained Traefik to Run on swarm-pi5-01

Added constraint to ensure Traefik runs on the node with VLAN 5 IP:
```bash
docker service update --constraint-add 'node.hostname==swarm-pi5-01' traefik_traefik
```

### 2. Added UFW Rule for Port 8080

Added explicit firewall rule (though rule #2 already allows 172.16.0.0/12):
```bash
sudo ufw allow from 172.16.5.0/24 to any port 8080 proto tcp
```

## Current Status

- ✅ Traefik constrained to `swarm-pi5-01`
- ✅ Port 8080 firewall rule added
- ✅ UFW rule #2 allows all traffic from 172.16.0.0/12 (includes VLAN 5)
- ✅ Dashboard working from node itself
- ⏳ Traefik service may still be starting

## Potential Remaining Issues

### 1. UniFi Firewall Rules

Even if UFW allows it, UniFi firewall rules might block:
- **VLAN 5 → VLAN 15**: Inter-VLAN routing
- **Port 8080**: Specific port restrictions

**Check in UniFi**:
- Firewall Rules → Ensure VLAN 5 can access VLAN 15
- Port 8080 specifically allowed if needed

### 2. Desktop Network Location

Verify your desktop is:
- **On VLAN 5** (172.16.5.x)
- **DNS resolving correctly**: `traefik.specterrealm.com` → `172.16.5.13`

### 3. Self-Signed Certificate

For `https://traefik.specterrealm.com/dashboard/`:
- Browser may block due to self-signed certificate
- **Solution**: Accept the security warning, or set Cloudflare token for proper certificates

## Testing Steps

### From Your Desktop

1. **Test DNS resolution**:
   ```bash
   nslookup traefik.specterrealm.com
   # Should return: 172.16.5.13
   ```

2. **Test port 8080**:
   ```bash
   curl http://172.16.5.13:8080/dashboard/
   # Should return: HTML with Traefik dashboard
   ```

3. **Test HTTPS dashboard**:
   ```bash
   curl -k https://traefik.specterrealm.com/dashboard/
   # Should return: HTML with Traefik dashboard
   ```

### From swarm-pi5-01 (for verification)

```bash
# Verify Traefik is running
docker ps | grep traefik

# Verify port 8080 is listening
sudo ss -tlnp | grep 8080

# Test locally
curl http://localhost:8080/dashboard/
```

## Next Steps

1. **Wait for Traefik to start**: Service may still be pending
2. **Check UniFi firewall**: Ensure VLAN 5 → VLAN 15 routing is allowed
3. **Verify desktop network**: Confirm you're on VLAN 5
4. **Test from desktop**: Try the curl commands above
5. **Set Cloudflare token**: Get proper SSL certificates

## If Still Not Working

1. **Check Traefik service status**:
   ```bash
   docker service ps traefik_traefik
   ```

2. **Check Traefik logs**:
   ```bash
   docker service logs traefik_traefik --tail 50
   ```

3. **Verify VLAN 5 IP**:
   ```bash
   ssh packer@swarm-pi5-01 "ip addr show eth0.5"
   ```

4. **Check UniFi firewall logs**: Look for blocked connections from VLAN 5

