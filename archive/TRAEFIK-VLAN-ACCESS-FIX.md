# Traefik VLAN Access Fix

## Issues

1. **Blank white page**: Traefik only accepts HTTPS, but HTTP redirect wasn't configured for specific routers
2. **VLAN access blocked**: Family VLAN (172.16.5.x) cannot access Management VLAN (172.16.15.x) due to firewall rules

## Fix 1: HTTP Redirect (Done)

Added HTTP redirect routers for `traefik.specterrealm.com` and `traefik-mgmt.specterrealm.com` so HTTP requests redirect to HTTPS.

## Fix 2: Firewall Rule Required

You need to add a firewall rule in UniFi to allow Family VLAN to access Traefik on Management VLAN.

### UniFi Firewall Rule

**Rule Name**: Allow Family VLAN to Traefik (Management VLAN)

**Configuration**:
- **Action**: Accept
- **Protocol**: TCP
- **Source**:
  - Type: Network
  - Network: Family (VLAN 5) - 172.16.5.0/24
- **Destination**:
  - Type: Address/Port Group
  - Address: 172.16.15.13 (swarm-pi5-01)
  - Port: 80, 443
- **State**: New, Established, Related, Invalid
- **Schedule**: Always
- **Logging**: Enabled (optional)

**Alternative**: Allow all Family VLAN to Management VLAN on ports 80/443:
- **Destination**: Management (VLAN 15) - 172.16.15.0/24
- **Port**: 80, 443

### Why This Is Needed

According to `specs-homelab/network/routing.md`:
- **Internal → Mgmt**: Block All (default policy)
- Family VLAN (172.16.5.x) is in "Internal" zone
- Management VLAN (172.16.15.x) is in "Mgmt" zone
- Therefore, Family VLAN cannot access Management VLAN by default

Since Traefik needs to be accessible from Family VLAN, we need to explicitly allow this traffic.

## Alternative Solution: Use Family VLAN IP

If you want to avoid firewall rules, you could:
1. Point DNS to an IP on Family VLAN (but Swarm nodes are on Management VLAN)
2. Use a reverse proxy on Family VLAN that forwards to Management VLAN
3. Move Traefik to use host networking with Family VLAN interface (complex)

**Recommended**: Add the firewall rule above - it's the cleanest solution.

## Next Steps

1. ✅ HTTP redirect routers added to Traefik stack
2. ⏳ Add firewall rule in UniFi (see above)
3. ⏳ Update Traefik stack (redeploy if needed)
4. ⏳ Test access from Family VLAN device

