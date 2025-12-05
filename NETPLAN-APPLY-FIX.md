# Netplan Apply Fix

## Problem

`netplan apply` is breaking SSH connectivity when configuring VLANs. This happens because:

1. **Network changes are applied immediately** - Can disrupt the current SSH session
2. **Multiple VLANs configured at once** - May cause routing conflicts
3. **Base interface might not be properly configured** - Could conflict with VLAN configs

## Root Cause Analysis

The playbook was:

1. Configuring base interface (disabling DHCP)
2. Creating VLAN interfaces
3. Configuring VLAN IPs
4. Applying netplan all at once

If the base interface doesn't have a static IP configured, or if there are routing conflicts, `netplan apply` can break connectivity.

## Fix Applied

### 1. Better Base Interface Configuration

- Ensures base interface has static IP before configuring VLANs
- Disables DHCP properly
- Removes default routes from base interface

### 2. Safer Netplan Apply

- Uses async execution to prevent hanging
- Adds connectivity check after apply
- Better error handling

### 3. Verification Steps

- Checks for multiple default routes
- Verifies connectivity after apply
- Warns if connectivity is lost

## Recovery Steps

If the node is locked out again:

**Via console:**

```bash
# 1. Check current netplan files
ls -la /etc/netplan/

# 2. Check base interface config
cat /etc/netplan/00-installer-config.yaml
# OR
cat /etc/netplan/50-cloud-init.yaml
# OR whatever file configures eth0

# 3. Ensure base interface has static IP and no default route
sudo nano /etc/netplan/<base-file>.yaml
```

**Should look like:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 172.16.15.13/24 # Your node IP
      nameservers:
        addresses:
          - 172.16.15.1
          - 1.1.1.1
      # NO routes section - default route only on eth0.15
```

**4. Check VLAN configs:**

```bash
# Should only have node IPs, not VIPs
grep -r "172.16.*\.2\|172.16.*\.3" /etc/netplan/50-vlan-*.yaml
# Should return nothing (VIPs managed by keepalived)
```

**5. Apply carefully:**

```bash
# Test first
sudo netplan --debug generate

# If OK, apply
sudo netplan apply

# Wait 10 seconds, then check
ip route show default
# Should show only: default via 172.16.15.1 dev eth0.15
```

## Alternative: Skip Network Role Temporarily

If network keeps breaking, you can skip it and configure manually:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml \
  --limit swarm-pi5-01 \
  --ask-become-pass \
  --skip-tags network
```

Then configure network manually or in smaller steps.
