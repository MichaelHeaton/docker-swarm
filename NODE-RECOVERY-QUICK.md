# Quick Recovery for swarm-pi5-01

## Problem

Ansible broke network connectivity again - likely DHCP on base eth0 interface creating conflicting routes.

## Console Access Recovery (Short Commands)

**Connect via console/monitor, then run these one at a time:**

```bash
# 1. Check current routes
ip route show

# 2. Check base interface config
cat /etc/netplan/00-installer-config.yaml

# 3. Disable DHCP on base interface
sudo nano /etc/netplan/00-installer-config.yaml
```

**In nano, change:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false # Change from true to false
      dhcp6: false # Change from true to false
```

**Save (Ctrl+O, Enter, Ctrl+X), then:**

```bash
# 4. Remove any DHCP-learned routes
sudo ip route del default via 172.16.15.1 dev eth0 2>/dev/null || true

# 5. Apply netplan
sudo netplan apply

# 6. Check routes (should be only ONE default route on eth0.15)
ip route show | grep default

# 7. Test connectivity
ping -c 2 172.16.15.1
```

## If Still Broken

**Check for multiple default routes:**

```bash
ip route show default
```

**Remove all except the one on eth0.15:**

```bash
# List all default routes
ip route show default

# Remove each one except eth0.15 (adjust based on output)
sudo ip route del default via <GATEWAY> dev <INTERFACE>
```

**Then verify:**

```bash
ip route show default
# Should show only: default via 172.16.15.1 dev eth0.15
```

## Root Cause Fix Needed

The Ansible playbook needs to:

1. Disable DHCP on base eth0 interface
2. Ensure only VLAN 15 has a default route
3. Validate before applying netplan
