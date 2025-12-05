# Base Interface Fix

## Problem

When disabling DHCP on the base interface, if a static IP isn't already configured in netplan, the interface loses its IP address and connectivity is broken.

## Root Cause

The playbook was:
1. Disabling DHCP on base interface
2. Applying netplan
3. But if the base interface was using DHCP to get its IP, disabling DHCP without ensuring a static IP is configured causes the interface to lose its IP

## Fix Applied

**Before disabling DHCP:**
1. Check if static IP is configured in netplan file
2. If not, add the static IP to the addresses section
3. Only then disable DHCP
4. Apply netplan

This ensures the interface always has an IP address configured, even when DHCP is disabled.

## Execution Flow

1. **Check base interface netplan file**
   - Find the file that configures eth0
   - Check if static IP is already configured

2. **Ensure static IP is configured** (if not present)
   - Add addresses section if missing
   - Add static IP to addresses list

3. **Disable DHCP** (if enabled)
   - Only disable if DHCP is currently enabled
   - This is safe now because static IP is already configured

4. **Remove default routes**
   - Comment out routes section (default route only on VLAN 15)

5. **Validate and apply**
   - Validate netplan configuration
   - Apply changes
   - Verify connectivity

## Safety

- ✅ Static IP is configured BEFORE disabling DHCP
- ✅ Interface never loses its IP address
- ✅ Connectivity is maintained throughout the process
- ✅ Early failure if connectivity is lost

