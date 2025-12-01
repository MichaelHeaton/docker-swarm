# Traefik Port 8080 VLAN 5 Access Fix

## Issue

Port 8080 returns "Connection refused" from desktop on VLAN 5, even though:
- ✅ Port is listening on `0.0.0.0:8080`
- ✅ Ping works to `172.16.5.13`
- ✅ Works from node itself
- ✅ Works on VLAN 15 IP (`172.16.15.13:8080`)

## Root Cause

Docker's iptables NAT rules for host mode ports use `!docker_gwbridge` which means they only apply to traffic NOT from docker_gwbridge. However, traffic coming from the VLAN 5 interface (`eth0.5`) may not be matching these rules correctly, causing the connection to be refused.

## Fix Applied

Added explicit iptables rules to handle traffic from the VLAN 5 interface:

### 1. NAT Rule for VLAN 5 Interface

```bash
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 8080 -j DNAT --to-destination 172.18.0.5:8080
```

This routes traffic from `eth0.5` on port 8080 to the Traefik container IP.

### 2. Forward Rules for VLAN 5 Traffic

```bash
# Allow traffic from VLAN 5 to docker_gwbridge
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 8080 -d 172.18.0.5 -j ACCEPT

# Allow return traffic from docker_gwbridge to VLAN 5
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 8080 -s 172.18.0.5 -j ACCEPT
```

These rules allow the traffic to flow between the VLAN 5 interface and Docker's network.

## Testing

From your desktop on VLAN 5:

```bash
# Test port 8080
curl http://172.16.5.13:8080/dashboard/

# Should now work!
```

## Making Rules Persistent

These iptables rules are temporary and will be lost on reboot. To make them persistent:

1. **Option 1**: Add to `/etc/rc.local` or a startup script
2. **Option 2**: Use `iptables-persistent` package
3. **Option 3**: Add to Ansible playbook for network configuration

## Alternative Solution

If iptables rules don't work, we could:
1. Change port 8080 from `host` mode to `ingress` mode (but this might affect other things)
2. Use a different port for the dashboard
3. Access dashboard only via HTTPS through Traefik routing

## Current Status

- ✅ NAT rule added for `eth0.5` → Traefik container
- ✅ Forward rules added for VLAN 5 ↔ Docker network
- ⚠️ Rules are temporary (will be lost on reboot)
- ⚠️ Need to make rules persistent

## Next Steps

1. **Test from desktop**: Try `curl http://172.16.5.13:8080/dashboard/`
2. **If working**: Make rules persistent
3. **If not working**: Check if Traefik container IP changed (currently `172.18.0.5`)

