#!/bin/bash
# Deploy AdGuard as a standalone container (not Swarm service)
# This allows us to use host networking and dedicated IP addresses
# Run this on swarm-pi5-01

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Deploying AdGuard as standalone container with host networking...${NC}"

# First, ensure IP aliases are configured
echo -e "${YELLOW}Configuring IP aliases...${NC}"
sudo ip addr add 172.16.5.2/32 dev eth0.5 2>/dev/null || true
sudo ip addr add 172.16.101.2/32 dev eth0.101 2>/dev/null || true
sudo ip addr add 172.16.15.2/32 dev eth0.15 2>/dev/null || true

# Stop and remove existing Swarm service (if running)
echo -e "${YELLOW}Removing existing Swarm service...${NC}"
docker service rm adguard_adguard 2>/dev/null || true

# Wait for service to be removed
sleep 2

# Stop and remove existing standalone container (if running)
echo -e "${YELLOW}Removing existing standalone container...${NC}"
docker stop adguard 2>/dev/null || true
docker rm adguard 2>/dev/null || true

# Ensure NFS directories exist
echo -e "${YELLOW}Checking NFS directories...${NC}"
sudo mkdir -p /mnt/nas/dockers/adguard/work
sudo mkdir -p /mnt/nas/dockers/adguard/conf
sudo chown -R 977:docker /mnt/nas/dockers/adguard

# Run AdGuard with host networking and NFS mounts
echo -e "${GREEN}Starting AdGuard container with host networking...${NC}"
docker run -d \
  --name adguard \
  --restart unless-stopped \
  --network host \
  --cap-add NET_BIND_SERVICE \
  -v /mnt/nas/dockers/adguard/work:/opt/adguardhome/work \
  -v /mnt/nas/dockers/adguard/conf:/opt/adguardhome/conf \
  -e TZ=${TRAEFIK_TIMEZONE:-UTC} \
  adguard/adguardhome:latest

echo ""
echo -e "${GREEN}✅ AdGuard deployed successfully!${NC}"
echo ""
echo -e "${GREEN}Container Status:${NC}"
docker ps | grep adguard

echo ""
echo -e "${GREEN}IP Addresses:${NC}"
echo -e "  ${GREEN}VLAN 5 (Family):${NC}    172.16.5.2"
echo -e "  ${GREEN}VLAN 101 (Guest):${NC}   172.16.101.2"
echo -e "  ${GREEN}VLAN 15 (Management):${NC} 172.16.15.2"

echo ""
echo -e "${YELLOW}Note: AdGuard is now running as a standalone container, not a Swarm service.${NC}"
echo -e "${YELLOW}This allows host networking and access to dedicated IP addresses.${NC}"

