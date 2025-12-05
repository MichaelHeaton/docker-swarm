#!/bin/bash
# Quick deployment script for AdGuard macvlan networks
# Run this directly on swarm-pi5-01

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Creating AdGuard macvlan networks...${NC}"

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

# Remove existing networks if they exist
echo -e "${YELLOW}Removing existing AdGuard networks (if any)...${NC}"
docker network rm adguard-vlan5 2>/dev/null || true
docker network rm adguard-vlan101 2>/dev/null || true
docker network rm adguard-vlan15 2>/dev/null || true

# Create macvlan network for VLAN 5 (Family) - 172.16.5.2
echo -e "${GREEN}Creating macvlan network for VLAN 5 (Family) - 172.16.5.2...${NC}"
docker network create -d macvlan \
  --subnet=172.16.5.0/24 \
  --gateway=172.16.5.1 \
  --ip-range=172.16.5.2/32 \
  -o parent=eth0.5 \
  adguard-vlan5

# Create macvlan network for VLAN 101 (Guest) - 172.16.101.2
echo -e "${GREEN}Creating macvlan network for VLAN 101 (Guest) - 172.16.101.2...${NC}"
docker network create -d macvlan \
  --subnet=172.16.101.0/24 \
  --gateway=172.16.101.1 \
  --ip-range=172.16.101.2/32 \
  -o parent=eth0.101 \
  adguard-vlan101

# Create macvlan network for VLAN 15 (Management) - 172.16.15.2
echo -e "${GREEN}Creating macvlan network for VLAN 15 (Management) - 172.16.15.2...${NC}"
docker network create -d macvlan \
  --subnet=172.16.15.0/24 \
  --gateway=172.16.15.1 \
  --ip-range=172.16.15.2/32 \
  -o parent=eth0.15 \
  adguard-vlan15

echo ""
echo -e "${GREEN}✅ AdGuard macvlan networks created successfully!${NC}"
echo ""
echo -e "${GREEN}Network Summary:${NC}"
echo -e "  ${GREEN}VLAN 5 (Family):${NC}    adguard-vlan5    → 172.16.5.2"
echo -e "  ${GREEN}VLAN 101 (Guest):${NC}   adguard-vlan101  → 172.16.101.2"
echo -e "  ${GREEN}VLAN 15 (Management):${NC} adguard-vlan15  → 172.16.15.2"
echo ""
echo -e "${YELLOW}Next step: Deploy AdGuard stack from your local machine:${NC}"
echo -e "  docker stack deploy -c stacks/adguard.yml adguard"

