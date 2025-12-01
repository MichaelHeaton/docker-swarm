# Traefik Access Fix

## Issues

1. **Port 8080 not accessible**: `http://172.16.5.13:8080` not working from desktop
2. **Dashboard path not accessible**: `https://traefik.specterrealm.com/dashboard/` not working from desktop

## Root Causes

### Port 8080 Issue

Port 8080 is in **host mode**, which means:
- It's only accessible on the node where Traefik is running
- Traefik was running on `swarm-pi5-03` (172.16.15.15), not `swarm-pi5-01` (172.16.5.13)
- **Fixed**: Added constraint to run Traefik on `swarm-pi5-01` where VLAN 5 IP is configured

### Dashboard Path Issue

The dashboard path might be blocked by:
1. **Firewall rules** - UFW or iptables blocking access from VLAN 5
2. **UniFi firewall rules** - Inter-VLAN routing restrictions
3. **Self-signed certificate** - Browser blocking the connection

## Solutions

### 1. Allow Port 8080 in Firewall (if needed)

If UFW is blocking port 8080 from VLAN 5:

```bash
# On swarm-pi5-01
sudo ufw allow from 172.16.5.0/24 to any port 8080 proto tcp
```

### 2. Check UniFi Firewall Rules

Ensure UniFi allows:
- **VLAN 5 → VLAN 15**: For accessing services on management network
- **Port 8080**: Specifically allowed if needed

### 3. Access Dashboard via HTTPS

Instead of port 8080, use:
- `https://traefik.specterrealm.com/dashboard/`
- Accept the security warning for self-signed certificate

### 4. Set Cloudflare Token (Proper Fix)

Set the Cloudflare API token to get valid SSL certificates:

```bash
# On any Swarm manager node
docker service update --env-add "CLOUDFLARE_DNS_API_TOKEN=your-token-here" traefik_traefik
```

## Current Status

- ✅ Traefik constrained to run on `swarm-pi5-01`
- ✅ Port 8080 listening on `swarm-pi5-01`
- ✅ Dashboard working from node itself
- ⚠️ Firewall rules may be blocking external access
- ⚠️ Self-signed certificate causing browser issues

## Testing

From your desktop (on VLAN 5):

```bash
# Test port 8080 (may be blocked by firewall)
curl http://172.16.5.13:8080/dashboard/

# Test HTTPS dashboard (may show cert warning)
curl -k https://traefik.specterrealm.com/dashboard/
```

## Next Steps

1. **Check firewall**: Verify UFW and UniFi rules allow VLAN 5 → VLAN 15 access
2. **Test port 8080**: Try accessing from desktop after firewall fix
3. **Set Cloudflare token**: Get proper SSL certificates
4. **Use HTTPS**: Prefer `https://traefik.specterrealm.com/dashboard/` over port 8080

