# AdGuard Multi-VLAN Setup Analysis

## Current State

### AdGuard Configuration

- **Current Network**: `mgmt-network` (VLAN 15 only)
- **IP Address**: 172.16.15.13 (via host networking)
- **DNS Ports**: 53 UDP/TCP (host mode - required for DNS)
- **Web UI**: Port 3000 (host mode)
- **Placement**: Pinned to `swarm-pi5-01`

### Network Requirements

- **VLAN 5 (Family)**: 172.16.5.0/24 - WiFi devices, phones, tablets
- **VLAN 101 (Guest)**: 172.16.101.0/24 - Guest network
- **VLAN 15 (Management)**: 172.16.15.0/24 - Current location

## Best Practices Research

### Single Instance vs Multiple Instances

**Recommended: Single Instance with Multiple IP Addresses**

**Pros:**

- ✅ **Single configuration** - One place to manage filters, rules, statistics
- ✅ **Unified statistics** - All queries in one dashboard
- ✅ **Consistent filtering** - Same blocklists across all VLANs
- ✅ **Lower resource usage** - One container vs multiple
- ✅ **Easier maintenance** - Update once, affects all VLANs
- ✅ **Simpler DNS forwarding** - One upstream configuration

**Cons:**

- ❌ **Single point of failure** - If AdGuard goes down, all VLANs affected (mitigated with HA)
- ❌ **Multi-homed networking** - Requires multiple IP addresses
- ❌ **Security consideration** - One service on multiple VLANs (acceptable for DNS)

**Alternative: Multiple Instances**

**Pros:**

- ✅ **VLAN isolation** - Each VLAN has its own instance
- ✅ **Independent configuration** - Different rules per VLAN
- ✅ **Reduced blast radius** - One VLAN failure doesn't affect others

**Cons:**

- ❌ **Multiple configurations** - Must maintain 3+ instances
- ❌ **Configuration drift** - Rules can get out of sync
- ❌ **More resources** - 3+ containers vs 1
- ❌ **Complex DNS forwarding** - Multiple upstream configs
- ❌ **Split statistics** - Can't see unified query stats

### Recommendation: Single Instance with Multi-Homed Networking

For DNS/ad-blocking services, **single instance with multiple IP addresses** is the industry standard because:

1. DNS is a critical infrastructure service - simpler is better
2. Unified statistics and configuration are valuable
3. DNS doesn't require strict VLAN isolation (it's a routing service)
4. Multi-homed networking is well-supported in Docker

## Implementation Options

### Option 1: Host Networking with Multiple IP Addresses (Recommended)

**Architecture:**

```
AdGuard Container
├── Network Mode: host
├── VLAN 5 IP: 172.16.5.13 (on eth0.5 interface)
├── VLAN 101 IP: 172.16.101.13 (on eth0.101 interface)
└── VLAN 15 IP: 172.16.15.13 (on eth0.15 interface)
```

**Configuration:**

- Use `network_mode: host` (required for DNS port 53)
- Bind AdGuard to listen on `0.0.0.0` (all interfaces)
- Configure IP addresses on host VLAN interfaces
- AdGuard will automatically listen on all interfaces

**Pros:**

- ✅ Works with DNS port 53 (host mode required)
- ✅ Simple configuration
- ✅ AdGuard listens on all interfaces automatically
- ✅ No Docker networking complexity

**Cons:**

- ❌ Bypasses Docker Swarm networking
- ❌ Can't use overlay networks for service discovery
- ❌ Port conflicts if multiple services use same ports

### Option 2: Macvlan Networks (Not Recommended for DNS)

**Architecture:**

```
AdGuard Container
├── Network: macvlan-vlan5 (172.16.5.13)
├── Network: macvlan-vlan101 (172.16.101.13)
└── Network: macvlan-vlan15 (172.16.15.13)
```

**Limitation:**

- ❌ Macvlan networks don't work well with Docker Swarm services
- ❌ DNS port 53 requires host mode anyway
- ❌ More complex configuration

### Option 3: Keep Current Setup + Firewall Rules

**Architecture:**

```
AdGuard Container (VLAN 15 only)
├── IP: 172.16.15.13
└── Firewall Rules: Allow VLAN 5 and 101 to reach VLAN 15 DNS
```

**Pros:**

- ✅ Simple - no network changes
- ✅ Maintains VLAN isolation

**Cons:**

- ❌ Requires firewall rules allowing VLAN 5/101 → VLAN 15
- ❌ Security concern - Guest VLAN can reach Management VLAN
- ❌ Not best practice - DNS should be accessible on client VLANs

## Recommended Solution: Option 1 (Host Networking with Multiple IPs)

### Implementation Steps

1. **Configure VLAN Interfaces on Host**

   - Add IP `172.16.5.13/24` to `eth0.5` on `swarm-pi5-01`
   - Add IP `172.16.101.13/24` to `eth0.101` on `swarm-pi5-01`
   - Keep existing `172.16.15.13/24` on `eth0.15`

2. **Update AdGuard Stack**

   - Use `network_mode: host`
   - AdGuard will automatically listen on all interfaces
   - Configure AdGuard to bind to `0.0.0.0` (default)

3. **Update DHCP Configuration**

   - VLAN 5 DHCP: Set DNS to `172.16.5.13`
   - VLAN 101 DHCP: Set DNS to `172.16.101.13`
   - VLAN 15 DHCP: Keep DNS as `172.16.15.13` (or UniFi)

4. **Update DNS Records**

   - `blocker.specterrealm.com` → `172.16.5.13` (VLAN 5)
   - `blocker-guest.specterrealm.com` → `172.16.101.13` (VLAN 101) (optional)
   - `adguard-mgmt.specterrealm.com` → `172.16.15.13` (VLAN 15)

5. **Security Considerations**
   - AdGuard on multiple VLANs is acceptable (DNS is a routing service)
   - No firewall rules needed (DNS is meant to be accessible)
   - Web UI access can be restricted via Traefik (already configured)

## Security Analysis

### Is Multi-VLAN DNS Secure?

**Yes, for DNS services:**

1. **DNS is a routing service** - It's designed to be accessible from client VLANs
2. **No data exposure** - DNS queries don't expose sensitive data
3. **AdGuard filtering** - Actually improves security by blocking malicious domains
4. **Web UI protection** - Management interface is protected via Traefik

### Firewall Rules

**No additional firewall rules needed:**

- DNS (port 53) should be accessible from client VLANs
- Web UI (port 3000) is already protected via Traefik
- AdGuard doesn't expose sensitive data

### VLAN Isolation

**Acceptable compromise:**

- DNS services are infrastructure services that need to be accessible
- Similar to how gateways (172.16.x.1) are accessible from all VLANs
- AdGuard doesn't store sensitive data that would compromise VLAN isolation

## Comparison with Traefik

Traefik uses a similar multi-homed approach:

- **VLAN 5**: 172.16.5.13
- **VLAN 15**: 172.16.15.13

This is the same pattern we're recommending for AdGuard.

## Next Steps

1. ✅ Review this analysis
2. ⏳ Configure VLAN interfaces on `swarm-pi5-01`
3. ⏳ Update AdGuard stack to use host networking
4. ⏳ Update DHCP DNS settings for VLAN 5 and 101
5. ⏳ Test DNS resolution from VLAN 5 and 101 devices
6. ⏳ Update documentation
