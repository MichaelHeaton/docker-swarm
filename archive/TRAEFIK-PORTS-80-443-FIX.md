# Traefik Ports 80 and 443 VLAN 5 Access Fix

## Issue

Ports 80 and 443 were not accessible from desktop on VLAN 5, even though:
- ✅ Ports were listening on `0.0.0.0:80` and `0.0.0.0:443` (docker-proxy)
- ✅ Worked from node itself
- ✅ Same issue as port 8080

## Root Cause

Docker's host mode port binding uses `docker-proxy` which listens on `0.0.0.0`, but Docker's iptables rules don't properly handle traffic from VLAN interfaces (`eth0.5`). Traffic from VLAN 5 needs explicit iptables rules to route to the Docker container.

## Fix Applied

Added comprehensive iptables rules for ports 80 and 443, similar to what we did for port 8080:

### 1. NAT Rules (PREROUTING)
```bash
# Route traffic from VLAN 5 interface to Traefik container
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 80 -j DNAT --to-destination 172.18.0.5:80
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 443 -j DNAT --to-destination 172.18.0.5:443

# Route traffic to VLAN 5 IP to Traefik container
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 80 -j DNAT --to-destination 172.18.0.5:80
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 443 -j DNAT --to-destination 172.18.0.5:443
```

### 2. Forward Rules (FORWARD)
```bash
# Allow traffic from VLAN 5 to docker_gwbridge
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 80 -d 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 443 -d 172.18.0.5 -j ACCEPT

# Allow return traffic from docker_gwbridge to VLAN 5
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 80 -s 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 443 -s 172.18.0.5 -j ACCEPT
```

### 3. MASQUERADE Rules (POSTROUTING)
```bash
# Masquerade return traffic
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 80 -j MASQUERADE
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 443 -j MASQUERADE
```

## Testing

From your desktop on VLAN 5:

```bash
# HTTP
curl http://172.16.5.13/

# HTTPS dashboard
curl -k https://172.16.5.13/dashboard/

# Via DNS
curl -k https://traefik.specterrealm.com/dashboard/
```

## Making Rules Persistent

These iptables rules are temporary and will be lost on reboot. To make them persistent:

1. **Save current rules**:
   ```bash
   sudo iptables-save > /etc/iptables/rules.v4
   ```

2. **Install iptables-persistent**:
   ```bash
   sudo apt-get install iptables-persistent
   ```

3. **Or add to Ansible playbook** for network configuration role

## Current Status

- ✅ NAT rules added for ports 80, 443, and 8080
- ✅ Forward rules added for ports 80, 443, and 8080
- ✅ MASQUERADE rules added for ports 80, 443, and 8080
- ⚠️ Rules are temporary (need to make persistent)
- ⚠️ Container IP may change on restart (currently `172.18.0.5`)

## Next Steps

1. **Test from desktop**: Try accessing HTTP and HTTPS URLs
2. **If working**: Make rules persistent
3. **If not working**: Check if container IP changed or if there are other blocking rules

