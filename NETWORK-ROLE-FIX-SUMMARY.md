# Network Role Fix Summary

## Changes Made

### 1. Base Interface Configuration (Before VLANs)

**Problem**: Base interface changes were being applied at the same time as VLAN changes, causing connectivity issues.

**Fix**:

- Disable DHCP on base interface FIRST
- Remove default routes from base interface FIRST
- Validate base interface config
- Apply base interface changes and verify connectivity
- ONLY THEN proceed with VLAN configuration

### 2. Connectivity Verification

**Added checks**:

- Verify base interface has static IP before proceeding
- Check connectivity to gateway after base interface changes
- Fail early if base interface connectivity is lost
- Verify only one default route after VLAN configuration

### 3. Safer Netplan Apply

**Improvements**:

- Apply base interface changes separately from VLAN changes
- Use async execution to prevent hanging
- Better error handling with `ignore_errors` where appropriate
- Wait for network to stabilize after each apply

## Execution Flow

1. **Base Interface Setup**

   - Find base interface netplan file
   - Disable DHCP4 and DHCP6
   - Comment out default routes
   - Validate configuration
   - Apply changes
   - Verify connectivity

2. **VLAN Configuration** (only if base interface is OK)
   - Create VLAN interfaces
   - Build VLAN configuration (node IPs only, no VIPs)
   - Generate netplan files for VLANs
   - Validate configuration
   - Check for conflicting routes
   - Apply VLAN configuration
   - Verify only one default route
   - Check connectivity

## Safety Features

- ✅ Base interface verified before VLAN changes
- ✅ Connectivity checks after each netplan apply
- ✅ Validation before applying
- ✅ Early failure if connectivity lost
- ✅ Only node IPs in netplan (VIPs managed by keepalived)

## Testing

Run the playbook:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml \
  --limit swarm-pi5-01 \
  --ask-become-pass
```

The playbook will:

1. Configure base interface first
2. Verify connectivity
3. Only then configure VLANs
4. Verify everything works

If connectivity is lost at any point, the playbook will fail early with a clear error message.
