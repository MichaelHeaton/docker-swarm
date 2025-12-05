#!/bin/bash
# Configure IP aliases for AdGuard on VLAN interfaces
# Run this on swarm-pi5-01
# These IPs allow AdGuard (using host networking) to have dedicated .2 IPs on each VLAN

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Configuring IP aliases for AdGuard on VLAN interfaces...${NC}"

# Check if VLAN interfaces exist
if ! ip link show eth0.5 >/dev/null 2>&1; then
    echo -e "${RED}Error: eth0.5 (VLAN 5) interface not found${NC}"
    exit 1
fi

if ! ip link show eth0.101 >/dev/null 2>&1; then
    echo -e "${RED}Error: eth0.101 (VLAN 101) interface not found${NC}"
    exit 1
fi

if ! ip link show eth0.15 >/dev/null 2>&1; then
    echo -e "${RED}Error: eth0.15 (VLAN 15) interface not found${NC}"
    exit 1
fi

# Remove existing IPs if they exist (in case of reconfiguration)
echo -e "${YELLOW}Removing existing IP aliases (if any)...${NC}"
ip addr del 172.16.5.2/32 dev eth0.5 2>/dev/null || true
ip addr del 172.16.101.2/32 dev eth0.101 2>/dev/null || true
ip addr del 172.16.15.2/32 dev eth0.15 2>/dev/null || true

# Add IP aliases for AdGuard
echo -e "${GREEN}Adding IP alias 172.16.5.2/32 to eth0.5...${NC}"
ip addr add 172.16.5.2/32 dev eth0.5

echo -e "${GREEN}Adding IP alias 172.16.101.2/32 to eth0.101...${NC}"
ip addr add 172.16.101.2/32 dev eth0.101

echo -e "${GREEN}Adding IP alias 172.16.15.2/32 to eth0.15...${NC}"
ip addr add 172.16.15.2/32 dev eth0.15

# Verify IPs
echo ""
echo -e "${GREEN}✅ IP aliases configured successfully!${NC}"
echo ""
echo -e "${GREEN}IP Summary:${NC}"
ip addr show eth0.5 | grep "172.16.5.2" || echo -e "${RED}  ❌ 172.16.5.2 not found on eth0.5${NC}"
ip addr show eth0.101 | grep "172.16.101.2" || echo -e "${RED}  ❌ 172.16.101.2 not found on eth0.101${NC}"
ip addr show eth0.15 | grep "172.16.15.2" || echo -e "${RED}  ❌ 172.16.15.2 not found on eth0.15${NC}"

echo ""
echo -e "${YELLOW}Note: These IP aliases are temporary and will be lost on reboot.${NC}"
echo -e "${YELLOW}To make them persistent, add to Netplan configuration or use a systemd service.${NC}"

