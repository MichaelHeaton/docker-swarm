# Uptime Kuma Network Fix

## Issue

Uptime Kuma was showing all services as down with "timeout of 48000ms exceeded" errors, even though:

- ✅ Services were actually up and accessible
- ✅ DNS resolution worked correctly
- ✅ Links worked when tested from Uptime Kuma's UI (browser)

## Root Cause

Uptime Kuma was running on `swarm-pi5-02`, which:

- ❌ Only has access to VLAN 15 (172.16.15.14)
- ❌ Cannot reach VLAN 5 (172.16.5.x) - 100% packet loss
- ❌ Has no route to VLAN 5

When Uptime Kuma tried to monitor services like:

- `https://blocker.specterrealm.com` → resolves to `172.16.5.13` (VLAN 5)
- `https://traefik.specterrealm.com` → resolves to `172.16.5.13` (VLAN 5)
- `https://portainer.specterrealm.com` → resolves to `172.16.5.13` (VLAN 5)

It couldn't reach them because `swarm-pi5-02` cannot access VLAN 5.

## Solution

**Pinned Uptime Kuma to `swarm-pi5-01`** which has:

- ✅ Access to VLAN 15 (172.16.15.13)
- ✅ Access to VLAN 5 (172.16.5.13)
- ✅ Routes to both VLANs configured

## Changes Made

Updated `stacks/uptime-kuma.yml`:

```yaml
deploy:
  replicas: 1
  placement:
    constraints:
      - node.role == manager
      - node.hostname == swarm-pi5-01 # Pin to node with VLAN 5 access
```

## Verification

After redeploying, Uptime Kuma should be able to:

1. ✅ Resolve DNS names correctly
2. ✅ Connect to services on VLAN 5 (via `172.16.5.13`)
3. ✅ Connect to services on VLAN 15 (via `172.16.15.13`)
4. ✅ Monitor all services successfully

## Alternative Solutions (Not Used)

### Option 1: Use Management URLs

Configure Uptime Kuma monitors to use management URLs:

- `https://portainer-mgmt.specterrealm.com` (VLAN 15)
- `https://adguard-mgmt.specterrealm.com` (VLAN 15)
- `https://traefik-mgmt.specterrealm.com` (VLAN 15)

**Problem**: This only monitors management interfaces, not the public-facing services that users actually access.

### Option 2: Add Firewall Rules

Add UniFi firewall rules to allow VLAN 15 to reach VLAN 5 for monitoring.

**Problem**: This violates the network security model where VLAN 15 (Management) should not access VLAN 5 (Family) by default.

### Option 3: Move Uptime Kuma to VLAN 5

Deploy Uptime Kuma on a node with VLAN 5 access.

**Problem**: Uptime Kuma needs to monitor services on both VLANs, so it needs access to both.

## Best Solution: Pin to Multi-Homed Node

Pinning Uptime Kuma to `swarm-pi5-01` (which has both VLANs) is the cleanest solution because:

- ✅ No firewall rule changes needed
- ✅ Can monitor both public (VLAN 5) and management (VLAN 15) services
- ✅ Matches the actual user experience (monitoring what users access)
- ✅ No network security model violations

## Next Steps

1. ✅ Uptime Kuma pinned to `swarm-pi5-01`
2. ⏳ Wait for service to restart (1-2 minutes)
3. ⏳ Verify monitors start working
4. ⏳ Check Uptime Kuma logs to confirm successful connections
