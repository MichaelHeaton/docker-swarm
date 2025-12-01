# Traefik VLAN 5 Access Complete Fix

## Issue Summary

Ports 80, 443, and 8080 were not accessible from desktop on VLAN 5, even though:
- ✅ Ports were listening on `0.0.0.0` (docker-proxy)
- ✅ Worked from node itself
- ✅ Ping worked from desktop

## Root Cause

Docker's host mode port binding uses `docker-proxy` which listens on all interfaces, but Docker's iptables rules don't properly handle traffic from VLAN interfaces (`eth0.5`). Additionally, UFW was missing explicit rules for ports 80 and 443 from VLAN 5.

## Complete Fix Applied

### 1. NAT Rules (PREROUTING)
```bash
# Route traffic from VLAN 5 interface to Traefik container
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 80 -j DNAT --to-destination 172.18.0.5:80
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 443 -j DNAT --to-destination 172.18.0.5:443
sudo iptables -t nat -I PREROUTING -i eth0.5 -p tcp --dport 8080 -j DNAT --to-destination 172.18.0.5:8080

# Route traffic to VLAN 5 IP to Traefik container
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 80 -j DNAT --to-destination 172.18.0.5:80
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 443 -j DNAT --to-destination 172.18.0.5:443
sudo iptables -t nat -I PREROUTING -d 172.16.5.13 -p tcp --dport 8080 -j DNAT --to-destination 172.18.0.5:8080
```

### 2. Forward Rules (FORWARD)
```bash
# Allow traffic from VLAN 5 to docker_gwbridge
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 80 -d 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 443 -d 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i eth0.5 -o docker_gwbridge -p tcp --dport 8080 -d 172.18.0.5 -j ACCEPT

# Allow return traffic from docker_gwbridge to VLAN 5
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 80 -s 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 443 -s 172.18.0.5 -j ACCEPT
sudo iptables -t filter -I FORWARD -i docker_gwbridge -o eth0.5 -p tcp --sport 8080 -s 172.18.0.5 -j ACCEPT
```

### 3. INPUT Rules (INPUT)
```bash
# Allow traffic on VLAN 5 interface
sudo iptables -t filter -I INPUT -i eth0.5 -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -I INPUT -i eth0.5 -p tcp --dport 443 -j ACCEPT
sudo iptables -t filter -I INPUT -i eth0.5 -p tcp --dport 8080 -j ACCEPT
```

### 4. UFW Rules
```bash
# Allow ports 80 and 443 from VLAN 5
sudo ufw allow from 172.16.5.0/24 to any port 80 proto tcp comment 'HTTP from VLAN 5'
sudo ufw allow from 172.16.5.0/24 to any port 443 proto tcp comment 'HTTPS from VLAN 5'

# Allow ports 80 and 443 from anywhere
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'
```

### 5. UFW Before-Input Rules
```bash
# Allow traffic before UFW processing
sudo iptables -t filter -I ufw-before-input -i eth0.5 -p tcp --dport 80 -j ACCEPT
sudo iptables -t filter -I ufw-before-input -i eth0.5 -p tcp --dport 443 -j ACCEPT
```

### 6. MASQUERADE Rules (POSTROUTING)
```bash
# Masquerade return traffic
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 80 -j MASQUERADE
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 443 -j MASQUERADE
sudo iptables -t nat -I POSTROUTING -o docker_gwbridge -s 172.18.0.5 -p tcp --sport 8080 -j MASQUERADE
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

# Port 8080
curl http://172.16.5.13:8080/dashboard/
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
- ✅ INPUT rules added for ports 80, 443, and 8080
- ✅ UFW rules added for ports 80 and 443
- ✅ UFW before-input rules added
- ✅ MASQUERADE rules added
- ⚠️ Rules are temporary (need to make persistent)
- ⚠️ Container IP may change on restart (currently `172.18.0.5`)

## Next Steps

1. **Test from desktop**: Try accessing HTTP and HTTPS URLs
2. **If working**: Make rules persistent via Ansible
3. **If not working**: Check if container IP changed or if there are other blocking rules

