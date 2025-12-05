# Emergency Fix for Netplan Configuration Issue

## Problem

The Ansible Netplan configuration added default routes (`to: 0.0.0.0/0`) to **all VLAN interfaces**, causing routing conflicts and breaking network connectivity.

## Immediate Fix Options

### Option 1: Fix via Physical Console (Recommended if SSH is down)

If you have physical/console access to swarm-pi5-01:

```bash
# Log in via console
# Edit the Netplan files to remove default routes from non-management VLANs
sudo nano /etc/netplan/50-vlan-5-family.yaml
# Remove the routes section (keep only addresses and nameservers)

sudo nano /etc/netplan/50-vlan-101-guest.yaml
# Remove the routes section

# Keep routes only in 50-vlan-15-mgmt.yaml

# Apply the fix
sudo netplan apply
```

### Option 2: Fix via Another Node (if you can SSH to other nodes)

If you can SSH to swarm-pi5-02, swarm-pi5-03, or swarm-pi5-04:

```bash
# SSH to another node
ssh swarm-pi5-02

# Try to SSH to swarm-pi5-01 via its management IP
ssh packer@172.16.15.13

# If that works, edit the Netplan files
sudo nano /etc/netplan/50-vlan-5-family.yaml
# Remove the routes section

sudo nano /etc/netplan/50-vlan-101-guest.yaml
# Remove the routes section

sudo netplan apply
```

### Option 3: Revert Netplan Files

If you have backups or can access the files:

```bash
# Remove the problematic Netplan files
sudo rm /etc/netplan/50-vlan-5-family.yaml
sudo rm /etc/netplan/50-vlan-101-guest.yaml
sudo rm /etc/netplan/50-vlan-10-production.yaml
sudo rm /etc/netplan/50-vlan-40-dmz.yaml

# Keep only the management VLAN config
# Then apply
sudo netplan apply
```

### Option 4: Use Netplan Try (if you have console access)

```bash
# This will test the configuration and revert if it breaks connectivity
sudo netplan try
```

## Root Cause

The template was adding default routes to all VLANs. Only the management VLAN (VLAN 15) should have a default route. Other VLANs should only have their IP addresses configured.

## Permanent Fix

The template has been updated to only add default routes to VLAN 15 (management). After fixing the immediate issue, re-run Ansible to apply the corrected configuration.

## Verification

After fixing, verify connectivity:

```bash
# Check routes
ip route show

# Should see only ONE default route (via 172.16.15.1)
# Check IP addresses
ip addr show

# Verify SSH works
ssh swarm-pi5-01
```

