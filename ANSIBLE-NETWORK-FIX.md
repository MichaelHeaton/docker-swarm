# Ansible Network Configuration Fix

## Problem

The Ansible playbook was breaking network connectivity because:

1. **Base interface (`eth0`) still had DHCP enabled** - This created a conflicting default route when netplan applied
2. **Validation wasn't strict enough** - It allowed conflicting routes to be applied
3. **No verification after applying** - Didn't check if multiple default routes existed after netplan apply

## Root Cause

When the base `eth0` interface has `dhcp4: true`, systemd-networkd or NetworkManager will:

- Get an IP address via DHCP
- Learn a default route via DHCP
- This conflicts with the static default route on `eth0.15` (VLAN 15)

Result: Multiple default routes → broken network connectivity

## Fix Applied

### 1. Disable DHCP on Base Interface

Added tasks to disable DHCP on the base interface before configuring VLANs:

```yaml
- name: Disable DHCP on base network interface
  # Ensures base interface doesn't get a default route via DHCP
```

### 2. Improved Validation

- Now fails if validation detects conflicting default routes
- Checks both stderr and stdout for route conflicts
- Provides clear error message

### 3. Post-Apply Verification

- Verifies only ONE default route exists after netplan apply
- Fails immediately if multiple routes detected
- Prevents broken state from persisting

## Recovery Steps

If the node is already broken, see `NODE-RECOVERY-QUICK.md` for console recovery steps.

## Testing

Before running on other nodes, test on `swarm-pi5-01`:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-become-pass
```

**After it completes, verify:**

```bash
# Should show only ONE default route (on eth0.15)
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "ip route show default"

# Should show all VLAN IPs configured
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "ip addr show | grep -E 'eth0\.(5|10|15|20|30|40|101|200)' | grep 'inet '"
```

## Next Steps

1. **Recover node 01** (if still broken) using recovery guide
2. **Test the fixed playbook** on node 01
3. **Verify network connectivity** works correctly
4. **Apply to other nodes** once verified
