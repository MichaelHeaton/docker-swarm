# Traefik Port 8080 Access Fix

## Issue

Port 8080 is not accessible from desktop on VLAN 5, even though:
- ✅ Port is listening on `0.0.0.0:8080`
- ✅ Both VLAN IPs are configured (`172.16.15.13` and `172.16.5.13`)
- ✅ Works from the node itself

## Root Cause

Port 8080 is in **host mode**, which means it binds directly to the host's network interfaces. However, Docker's iptables rules or UFW might be blocking external connections.

## Fixes Applied

### 1. Added UFW Rule for Port 8080

```bash
sudo ufw allow 8080/tcp comment 'Traefik dashboard'
```

### 2. Added Direct iptables Rule

```bash
sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
```

This ensures port 8080 is accessible regardless of Docker's iptables rules.

## Testing

From your desktop on VLAN 5:

```bash
# Test port 8080
curl http://172.16.5.13:8080/dashboard/

# Test HTTPS dashboard
curl -k https://traefik.specterrealm.com/dashboard/
```

## If Still Not Working

### Check UniFi Firewall

Even though the node has both VLAN IPs, UniFi might be blocking:
- **Inter-VLAN routing**: Check if VLAN 5 devices can reach other VLAN 5 devices
- **Port 8080**: Check if there are any port-specific rules

### Verify Port Binding

```bash
# On swarm-pi5-01
sudo ss -tlnp | grep 8080
# Should show: 0.0.0.0:8080

# Test from node itself
curl http://172.16.5.13:8080/dashboard/
# Should work

# Test from another VLAN 5 device
# Should work after firewall fixes
```

### Check Docker Port Mapping

```bash
docker ps --filter 'name=traefik' --format '{{.Ports}}'
# Should show: 0.0.0.0:8080->8080/tcp
```

## Current Status

- ✅ Port 8080 listening on all interfaces
- ✅ UFW rule added for port 8080
- ✅ iptables rule added for port 8080
- ⚠️ May need UniFi firewall rule if still blocked

## Next Steps

1. **Test from desktop**: Try `curl http://172.16.5.13:8080/dashboard/`
2. **Check UniFi**: Verify VLAN 5 → VLAN 5 routing is allowed
3. **Check logs**: If still failing, check system logs for connection attempts

