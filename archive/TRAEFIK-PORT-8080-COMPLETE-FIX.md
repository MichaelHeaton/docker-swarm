# Traefik Port 8080 Complete Fix

## Issue

Port 8080 returns "Connection refused" from desktop on VLAN 5, even though:
- ✅ Port is listening on `0.0.0.0:8080` (docker-proxy)
- ✅ Ping works to `172.16.5.13`
- ✅ Works from node itself
- ✅ Works on VLAN 15 IP (`172.16.15.13:8080`)

## Root Cause Analysis

The problem is that Docker's host mode port binding uses `docker-proxy` which listens on `0.0.0.0:8080`, but Docker's iptables rules are designed for the default network interface. When traffic comes from a VLAN interface (`eth0.5`), it may not match Docker's default iptables rules correctly.

## Complete Fix Applied

### 1. NAT Rules (PREROUTING)
```bash
# Route traffic from VLAN 5 interface to Traefik container
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 8080 -j DNAT --to-destination 172.18.0.5:8080

# Route traffic to VLAN 5 IP to Traefik container
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 8080 -j DNAT --to-destination 172.18.0.5:8080
```

### 2. Forward Rules (FORWARD)
```bash
# Allow traffic from VLAN 5 to docker_gwbridge
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 8080 -d 172.18.0.5 -j ACCEPT

# Allow return traffic from docker_gwbridge to VLAN 5
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 8080 -s 172.18.0.5 -j ACCEPT
```

### 3. Input Rules (INPUT)
```bash
# Allow traffic on VLAN 5 interface to port 8080
sudo iptables -t filter -I INPUT -i eth0.5 -p tcp --dport 8080 -j ACCEPT
```

### 4. Docker-Specific Rules
```bash
# DOCKER-USER chain (processed before DOCKER chain)
sudo iptables -t filter -I DOCKER-USER -i eth0.5 -p tcp --dport 8080 -j ACCEPT

# DOCKER-FORWARD chain (for forwarded traffic)
sudo iptables -t filter -I DOCKER-FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 8080 -d 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I DOCKER-FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 8080 -s 172.18.0.5 -j ACCEPT
```

### 5. MASQUERADE Rule (POSTROUTING)
```bash
# Masquerade return traffic
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 8080 -j MASQUERADE
```

## Testing

From your desktop on VLAN 5:

```bash
curl http://172.16.5.13:8080/dashboard/
```

## Making Rules Persistent

These iptables rules are temporary. To make them persistent:

1. **Save current rules**:
   ```bash
   sudo iptables-save > /etc/iptables/rules.v4
   ```

2. **Install iptables-persistent**:
   ```bash
   sudo apt-get install iptables-persistent
   ```

3. **Or add to Ansible playbook** for network configuration role

## Alternative: Use Ingress Mode

If iptables rules continue to be problematic, consider changing port 8080 from `host` mode to `ingress` mode in the Traefik stack file. However, this may affect how the dashboard is accessed.

## Current Status

- ✅ NAT rules added
- ✅ Forward rules added
- ✅ Input rules added
- ✅ Docker-specific rules added
- ✅ MASQUERADE rule added
- ⚠️ Rules are temporary (need to make persistent)
- ⚠️ Container IP may change on restart (currently `172.18.0.5`)

## Next Steps

1. **Test from desktop**: Try `curl http://172.16.5.13:8080/dashboard/`
2. **If working**: Make rules persistent
3. **If not working**: Check if container IP changed or if there are other blocking rules

