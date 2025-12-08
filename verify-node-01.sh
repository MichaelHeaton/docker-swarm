#!/bin/bash
# Verification script for swarm-pi5-01 (node 0)
# Run this to check networking and configuration before rebuilding other nodes
# Note: VLAN 15 is untagged on eth0 (base interface), not eth0.15

set -e

echo "=========================================="
echo "swarm-pi5-01 Network & Configuration Check"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track issues
ISSUES=0

echo "1. Checking VLAN Interfaces..."
echo "-------------------------------"
# Note: VLAN 15 is untagged on eth0 (base interface), not eth0.15
EXPECTED_VLANS=(5 10 20 30 40 101 200)
MISSING_VLANS=()

for vlan in "${EXPECTED_VLANS[@]}"; do
    if ip link show eth0.$vlan &>/dev/null; then
        echo -e "${GREEN}✓${NC} eth0.$vlan exists"
    else
        echo -e "${RED}✗${NC} eth0.$vlan MISSING"
        MISSING_VLANS+=($vlan)
        ((ISSUES++))
    fi
done

# Check VLAN 15 separately (it's on eth0, not eth0.15)
if ip addr show eth0 2>/dev/null | grep -q "172.16.15"; then
    echo -e "${GREEN}✓${NC} eth0 (VLAN 15 untagged) exists"
else
    echo -e "${YELLOW}⚠${NC} eth0 (VLAN 15 untagged) - checking..."
fi

echo ""
echo "1b. Checking Hostname..."
echo "------------------------"
CURRENT_HOSTNAME=$(hostname)
EXPECTED_HOSTNAME="swarm-pi5-01"
if [ "$CURRENT_HOSTNAME" == "$EXPECTED_HOSTNAME" ]; then
    echo -e "${GREEN}✓${NC} Hostname is correct: $CURRENT_HOSTNAME"
else
    echo -e "${RED}✗${NC} Hostname is INCORRECT: $CURRENT_HOSTNAME (expected: $EXPECTED_HOSTNAME)"
    ((ISSUES++))
fi

echo ""
echo "2. Checking IP Addresses on VLANs..."
echo "------------------------------------"
# Expected IPs based on node 0 (.13)
# Note: VLAN 15 is on eth0 (untagged), not eth0.15
declare -A EXPECTED_IPS=(
    ["eth0.5"]="172.16.5.13"
    ["eth0.10"]="172.16.10.13"
    ["eth0"]="172.16.15.13"  # VLAN 15 is untagged on base interface
    ["eth0.20"]="172.16.20.13"
    ["eth0.30"]="172.16.30.13"
    ["eth0.40"]="172.16.40.13"
    ["eth0.101"]="172.16.101.13"
    ["eth0.200"]="172.16.200.13"
)

for iface in "${!EXPECTED_IPS[@]}"; do
    expected_ip="${EXPECTED_IPS[$iface]}"
    if ip addr show $iface 2>/dev/null | grep -q "$expected_ip"; then
        if [ "$iface" == "eth0" ]; then
            echo -e "${GREEN}✓${NC} $iface (VLAN 15 untagged) has $expected_ip"
        else
            echo -e "${GREEN}✓${NC} $iface has $expected_ip"
        fi
    else
        if [ "$iface" == "eth0" ]; then
            echo -e "${RED}✗${NC} $iface (VLAN 15 untagged) missing $expected_ip"
        else
            echo -e "${RED}✗${NC} $iface missing $expected_ip"
        fi
        ((ISSUES++))
    fi
done

echo ""
echo "3. Checking Default Routes (should be ONLY ONE)..."
echo "---------------------------------------------------"
DEFAULT_ROUTES=$(ip route show | grep default | wc -l)
if [ "$DEFAULT_ROUTES" -eq 1 ]; then
    DEFAULT_ROUTE=$(ip route show | grep default)
    # Default route should be on eth0 (VLAN 15 untagged) or eth0.15 (if VLAN 15 was created as tagged)
    if echo "$DEFAULT_ROUTE" | grep -qE "(eth0\.15|eth0 )"; then
        echo -e "${GREEN}✓${NC} Only one default route: $DEFAULT_ROUTE"
    else
        echo -e "${YELLOW}⚠${NC} Default route exists but not on eth0/eth0.15: $DEFAULT_ROUTE"
        ((ISSUES++))
    fi
elif [ "$DEFAULT_ROUTES" -eq 0 ]; then
    echo -e "${RED}✗${NC} NO default route found!"
    ((ISSUES++))
else
    echo -e "${RED}✗${NC} MULTIPLE default routes found ($DEFAULT_ROUTES):"
    ip route show | grep default | while read route; do
        echo "  - $route"
    done
    ((ISSUES++))
fi

echo ""
echo "4. Checking VIPs (Keepalived)..."
echo "---------------------------------"
# DNS VIPs (.2)
DNS_VIPS=("172.16.5.2" "172.16.15.2" "172.16.101.2")
for vip in "${DNS_VIPS[@]}"; do
    if ip addr show | grep -q "$vip"; then
        echo -e "${GREEN}✓${NC} DNS VIP $vip configured"
    else
        echo -e "${YELLOW}⚠${NC} DNS VIP $vip not found (may be on another node)"
    fi
done

# Traefik VIPs (.3)
TRAEFIK_VIPS=("172.16.5.3" "172.16.15.3" "172.16.101.3" "172.16.40.3")
for vip in "${TRAEFIK_VIPS[@]}"; do
    if ip addr show | grep -q "$vip"; then
        echo -e "${GREEN}✓${NC} Traefik VIP $vip configured"
    else
        echo -e "${YELLOW}⚠${NC} Traefik VIP $vip not found (may be on another node)"
    fi
done

echo ""
echo "5. Checking NFS Mounts..."
echo "-------------------------"
NFS_MOUNTS=(
    # Docker storage - both medium and high IOPS
    "/mnt/nas/dockers"          # Medium IOPS from NAS02
    "/mnt/nas/dockers-iops"    # High IOPS from NAS01
    # Media shares from NAS02
    "/mnt/nas/media_streaming"
    "/mnt/nas/media_family"
    "/mnt/nas/media_stashapp"
    # Backup share from NAS01
    "/mnt/nas/backups"
)

for mount in "${NFS_MOUNTS[@]}"; do
    if mountpoint -q "$mount" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} $mount is mounted"
    else
        echo -e "${RED}✗${NC} $mount is NOT mounted"
        ((ISSUES++))
    fi
done

echo ""
echo "6. Checking Docker Status..."
echo "---------------------------"
if systemctl is-active --quiet docker; then
    echo -e "${GREEN}✓${NC} Docker service is running"
else
    echo -e "${RED}✗${NC} Docker service is NOT running"
    ((ISSUES++))
fi

echo ""
echo "7. Checking Docker Swarm Status..."
echo "----------------------------------"
if docker info --format '{{.Swarm.LocalNodeState}}' 2>/dev/null | grep -q "active"; then
    SWARM_STATE=$(docker info --format '{{.Swarm.LocalNodeState}}')
    echo -e "${GREEN}✓${NC} Docker Swarm is active (state: $SWARM_STATE)"

    if docker info --format '{{.Swarm.ControlAvailable}}' 2>/dev/null | grep -q "true"; then
        echo -e "${GREEN}✓${NC} Node is a Swarm manager"
    else
        echo -e "${YELLOW}⚠${NC} Node is a Swarm worker"
    fi

    echo ""
    echo "Swarm nodes:"
    docker node ls 2>/dev/null || echo "  (Cannot list nodes)"
else
    echo -e "${RED}✗${NC} Docker Swarm is NOT active"
    ((ISSUES++))
fi

echo ""
echo "8. Checking Keepalived Status..."
echo "---------------------------------"
if systemctl is-active --quiet keepalived; then
    echo -e "${GREEN}✓${NC} Keepalived service is running"
    KEEPALIVED_STATE=$(systemctl show keepalived --property=ActiveState --value)
    echo "  State: $KEEPALIVED_STATE"
else
    echo -e "${YELLOW}⚠${NC} Keepalived service is NOT running (may not be configured on this node)"
fi

echo ""
echo "9. Testing Connectivity..."
echo "--------------------------"
# Test gateway
if ping -c 1 -W 2 172.16.15.1 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Gateway (172.16.15.1) is reachable"
else
    echo -e "${RED}✗${NC} Gateway (172.16.15.1) is NOT reachable"
    ((ISSUES++))
fi

# Test NAS storage
if ping -c 1 -W 2 172.16.30.5 &>/dev/null; then
    echo -e "${GREEN}✓${NC} NAS01 storage (172.16.30.5) is reachable"
else
    echo -e "${YELLOW}⚠${NC} NAS01 storage (172.16.30.5) is NOT reachable (may be expected if NAS is down)"
fi

# Test internet
if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Internet (8.8.8.8) is reachable"
else
    echo -e "${YELLOW}⚠${NC} Internet (8.8.8.8) is NOT reachable"
fi

echo ""
echo "10. Checking Docker Services..."
echo "-------------------------------"
if docker service ls &>/dev/null; then
    SERVICE_COUNT=$(docker service ls --format '{{.Name}}' 2>/dev/null | wc -l)
    echo "Active services: $SERVICE_COUNT"
    docker service ls 2>/dev/null || echo "  (Cannot list services)"
else
    echo -e "${YELLOW}⚠${NC} Cannot check Docker services (Swarm may not be initialized)"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
if [ $ISSUES -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo "Node 1 is ready. You can proceed with rebuilding nodes 2, 3, and 4."
    exit 0
else
    echo -e "${RED}✗ Found $ISSUES issue(s)${NC}"
    echo "Please fix the issues above before rebuilding other nodes."
    exit 1
fi

