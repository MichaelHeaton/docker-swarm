# AdGuard Multi-VLAN Setup Summary

## Decision: Single Instance with Dedicated IP Addresses ✅

**Updated Approach**: AdGuard uses **macvlan networks** to get dedicated IP addresses on each VLAN, separate from the Swarm node IPs. This makes it clear these are DNS server IPs, not Swarm cluster IPs.

### IP Address Allocation

- **VLAN 5 (Family)**: `172.16.5.2` - Dedicated DNS server IP
- **VLAN 101 (Guest)**: `172.16.101.2` - Dedicated DNS server IP
- **VLAN 15 (Management)**: `172.16.15.2` - Dedicated DNS server IP

**Note**: Using `.2` on each VLAN provides consistency and avoids conflicts with:

- `.1` - Gateway IPs
- `.10` - GPU01 IPs (reserved)
- `.13-.16` - Raspberry Pi node IPs (reserved)

### Why Dedicated IPs?

1. **Clear Identification** - Easy to identify as DNS server IPs, not Swarm node IPs
2. **Separation of Concerns** - DNS service has its own IP space
3. **No Confusion** - Won't get mixed up with cluster management IPs
4. **Standard Practice** - DNS servers typically have dedicated IPs

## Implementation

### Changes Made

1. ✅ **Updated AdGuard Stack** (`stacks/adguard.yml`)

   - Changed to use macvlan networks instead of host networking
   - AdGuard gets dedicated IPs: `172.16.5.2`, `172.16.101.2`, `172.16.15.2`
   - Works with Docker Swarm because service is pinned to one node
   - Using `.2` for consistency across all VLANs and to avoid IP conflicts

2. ✅ **Created Network Setup Script** (`stacks/create-adguard-networks.sh`)

   - Script to create macvlan networks on `swarm-pi5-01`
   - Creates networks: `adguard-vlan5`, `adguard-vlan101`, `adguard-vlan15`

3. ✅ **Updated Traefik Routes** (`stacks/dynamic/adguard-routes.yml`)

   - Routes point to `172.16.15.2:3000` (AdGuard management IP)

4. ✅ **Updated Documentation**
   - Implementation guide updated with macvlan approach
   - All IP addresses updated to dedicated DNS IPs

### Next Steps (Manual)

1. **Create Macvlan Networks** on `swarm-pi5-01`:

   ```bash
   ./stacks/create-adguard-networks.sh
   ```

2. **Deploy Updated Stack**:

   ```bash
   docker stack deploy -c stacks/adguard.yml adguard
   ```

3. **Update DHCP DNS Settings** (UniFi Controller):

   - VLAN 5: Primary DNS → `172.16.5.2`
   - VLAN 101: Primary DNS → `172.16.101.2`
   - VLAN 15: Primary DNS → `172.16.15.2`

4. **Update DNS Records** (UniFi Controller):

   - `blocker.specterrealm.com` → `172.16.5.2`
   - `adguard-mgmt.specterrealm.com` → `172.16.15.2`

5. **Configure AdGuard**:

   - Access: `https://adguard-mgmt.specterrealm.com` or `https://172.16.15.2:3000`
   - Verify "Listen interfaces" is set to `0.0.0.0`

6. **Test DNS Resolution**:
   - From VLAN 5: `nslookup google.com 172.16.5.2`
   - From VLAN 101: `nslookup google.com 172.16.101.2`
   - From VLAN 15: `nslookup google.com 172.16.15.2`

## Network Architecture

```
AdGuard Container (Macvlan Networks)
├── adguard-vlan5
│   └── IP: 172.16.5.2/24
│       └── DNS: Port 53 (UDP/TCP)
│       └── Web UI: Port 3000
├── adguard-vlan101
│   └── IP: 172.16.101.2/24
│       └── DNS: Port 53 (UDP/TCP)
│       └── Web UI: Port 3000
└── adguard-vlan15
    └── IP: 172.16.15.2/24
        └── DNS: Port 53 (UDP/TCP)
        └── Web UI: Port 3000
```

## Access Methods

### DNS Access

- **VLAN 5**: `172.16.5.10:53` (via DHCP)
- **VLAN 101**: `172.16.101.10:53` (via DHCP)
- **VLAN 15**: `172.16.15.17:53` (via DHCP)

### Web UI Access

- **Via Traefik** (recommended):
  - Public: `https://blocker.specterrealm.com` (VLAN 5)
  - Management: `https://adguard-mgmt.specterrealm.com` (VLAN 15)
- **Direct Access**:
  - VLAN 5: `https://172.16.5.10:3000`
  - VLAN 101: `https://172.16.101.10:3000`
  - VLAN 15: `https://172.16.15.17:3000`

## Benefits of Using .2 IP Address

1. ✅ **Consistency** - Same `.2` IP across all VLANs makes it easy to remember
2. ✅ **No Conflicts** - Avoids conflicts with:
   - `.1` - Gateway IPs
   - `.10` - GPU01 IPs (reserved)
   - `.13-.16` - Raspberry Pi node IPs (reserved)
3. ✅ **Clear Identification** - `.2` is clearly a DNS server IP, not a node IP
4. ✅ **Future-Proof** - If DNS service changes, just update `.2` to point to new server
5. ✅ **Separation** - DNS service has its own dedicated IP space
6. ✅ **Standard Practice** - DNS servers typically have dedicated IPs

## Files Modified

- ✅ `stacks/adguard.yml` - Updated to use macvlan networks
- ✅ `stacks/create-adguard-networks.sh` - New script to create macvlan networks
- ✅ `stacks/dynamic/adguard-routes.yml` - Updated Traefik routes
- ✅ `ADGUARD-MULTI-VLAN-IMPLEMENTATION.md` - Updated implementation guide
- ✅ `ADGUARD-MULTI-VLAN-SUMMARY.md` - This summary
