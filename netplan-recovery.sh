#!/bin/bash
# Netplan Recovery Script
# Run this on each affected node (swarm-pi5-01, swarm-pi5-03, swarm-pi5-04) via console
# This removes the problematic default routes from non-management VLANs

set -e

echo "=========================================="
echo "Netplan Recovery Script"
echo "=========================================="
echo ""
echo "This script will fix the routing issue by removing default routes"
echo "from VLANs 5, 10, 40, and 101 (keeping only VLAN 15 with default route)"
echo ""

# Function to fix a Netplan file
fix_netplan_file() {
    local file=$1
    local vlan_name=$2

    if [ ! -f "$file" ]; then
        echo "⚠️  File $file not found, skipping..."
        return
    fi

    echo "Fixing $vlan_name ($file)..."

    # Create a backup
    cp "$file" "${file}.backup-$(date +%Y%m%d-%H%M%S)"

    # Remove the routes section (lines with "routes:" through the "via:" line)
    # Using a temporary file to avoid sed issues
    awk '
        /^[[:space:]]*routes:/ {
            skip=1
            next
        }
        /^[[:space:]]*- to: 0\.0\.0\.0\/0/ {
            skip=1
            next
        }
        /^[[:space:]]*via:/ {
            skip=1
            next
        }
        {
            if (!skip) print
            if (skip && /^[[:space:]]*[a-z]/) skip=0
        }
    ' "$file" > "${file}.tmp" && mv "${file}.tmp" "$file"

    echo "✅ Fixed $vlan_name"
}

# Fix VLAN 5 (Family)
fix_netplan_file "/etc/netplan/50-vlan-5-family.yaml" "VLAN 5 (Family)"

# Fix VLAN 10 (Production)
fix_netplan_file "/etc/netplan/50-vlan-10-production.yaml" "VLAN 10 (Production)"

# Fix VLAN 40 (DMZ)
fix_netplan_file "/etc/netplan/50-vlan-40-dmz.yaml" "VLAN 40 (DMZ)"

# Fix VLAN 101 (Guest)
fix_netplan_file "/etc/netplan/50-vlan-101-guest.yaml" "VLAN 101 (Guest)"

# Fix primary interface (eth0) - remove default route if present
if [ -f /etc/netplan/00-installer-config.yaml ]; then
    echo "Fixing primary interface (eth0)..."
    fix_netplan_file "/etc/netplan/00-installer-config.yaml" "Primary Interface (eth0)"
fi

# Keep VLAN 15 (Management) as-is - it should have the default route

echo ""
echo "=========================================="
echo "Validating Netplan configuration..."
echo "=========================================="
sudo netplan --debug generate

echo ""
echo "=========================================="
echo "Applying Netplan configuration..."
echo "=========================================="
sudo netplan apply

echo ""
echo "=========================================="
echo "Verification"
echo "=========================================="
echo ""
echo "Checking routes (should see only ONE default route via 172.16.15.1):"
ip route show | grep default || echo "No default route found (this might be OK if using static routes)"

echo ""
echo "Checking VLAN interfaces:"
ip addr show | grep -E "eth0\.(5|10|15|40|101)" | grep "inet " || echo "No VLAN IPs found"

echo ""
echo "=========================================="
echo "✅ Recovery complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Test SSH connectivity: ssh packer@172.16.15.X"
echo "2. If working, re-run Ansible with the fixed template:"
echo "   cd ansible"
echo "   ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network"
echo ""

