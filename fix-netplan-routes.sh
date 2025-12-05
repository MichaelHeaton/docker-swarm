#!/bin/bash
# Emergency script to fix Netplan routing issue
# Run this on each affected node (swarm-pi5-01, swarm-pi5-03, swarm-pi5-04)

set -e

echo "Fixing Netplan configuration - removing default routes from non-management VLANs..."

# Remove default routes from VLAN 5
if [ -f /etc/netplan/50-vlan-5-family.yaml ]; then
    echo "Fixing VLAN 5 config..."
    sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-5-family.yaml
fi

# Remove default routes from VLAN 101
if [ -f /etc/netplan/50-vlan-101-guest.yaml ]; then
    echo "Fixing VLAN 101 config..."
    sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-101-guest.yaml
fi

# Remove default routes from VLAN 10
if [ -f /etc/netplan/50-vlan-10-production.yaml ]; then
    echo "Fixing VLAN 10 config..."
    sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-10-production.yaml
fi

# Remove default routes from VLAN 40
if [ -f /etc/netplan/50-vlan-40-dmz.yaml ]; then
    echo "Fixing VLAN 40 config..."
    sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-40-dmz.yaml
fi

# Keep routes in VLAN 15 (management) - don't touch it

echo "Applying Netplan configuration..."
sudo netplan apply

echo "✅ Fixed! Check connectivity:"
echo "  ip route show"
echo "  (Should see only ONE default route via 172.16.15.1)"


