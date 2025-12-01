#!/bin/bash
# Create macvlan networks for Traefik static IPs on VLAN interfaces
# Run this on each Swarm node that will run Traefik

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating macvlan networks for Traefik static IPs...${NC}"

# Check if VLAN interfaces exist
if ! ip link show eth0.5 >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: eth0.5 (VLAN 5) interface not found${NC}"
    exit 1
fi

if ! ip link show eth0.15 >/dev/null 2>&1; then
    echo -e "${YELLOW}Warning: eth0.15 (VLAN 15) interface not found${NC}"
    exit 1
fi

# Remove existing macvlan networks if they exist
docker network rm vlan5_macvlan 2>/dev/null || true
docker network rm vlan15_macvlan 2>/dev/null || true

# Create macvlan network for VLAN 5 (Family) - 172.16.5.10
echo -e "${GREEN}Creating macvlan network for VLAN 5 (Family)...${NC}"
docker network create -d macvlan \
  --subnet=172.16.5.0/24 \
  --gateway=172.16.5.1 \
  --ip-range=172.16.5.10/32 \
  -o parent=eth0.5 \
  vlan5_macvlan

# Create macvlan network for VLAN 15 (Management) - 172.16.15.17
echo -e "${GREEN}Creating macvlan network for VLAN 15 (Management)...${NC}"
docker network create -d macvlan \
  --subnet=172.16.15.0/24 \
  --gateway=172.16.15.1 \
  --ip-range=172.16.15.17/32 \
  -o parent=eth0.15 \
  vlan15_macvlan

echo -e "${GREEN}Macvlan networks created successfully!${NC}"
echo -e "${GREEN}VLAN 5 (Family): vlan5_macvlan - 172.16.5.10${NC}"
echo -e "${GREEN}VLAN 15 (Management): vlan15_macvlan - 172.16.15.17${NC}"

