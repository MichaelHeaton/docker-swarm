# VLAN Configuration Fix

## Problem

The Ansible playbook was adding AdGuard VIPs (`.2` IPs) as **static IPs** in netplan, but these are **Virtual IPs (VIPs)** that should be managed by **keepalived**, not netplan.

### What Was Happening

1. Netplan was trying to assign `172.16.5.2`, `172.16.15.2`, `172.16.101.2` as static IPs
2. These IPs are VIPs that float between nodes via keepalived
3. Having them as static IPs causes conflicts and breaks network connectivity

### The Fix

**Removed VIPs from netplan configuration:**

- Only node IPs (`.13`, `.14`, `.15`, `.16`) are configured in netplan
- VIPs (`.2` for DNS, `.3` for Traefik) are managed by keepalived
- Keepalived adds/removes VIPs dynamically based on node priority and health

## What Changed

### Before (BROKEN)

```yaml
addresses:
  - 172.16.5.13/24 # Node IP
  - 172.16.5.2/32 # AdGuard VIP (WRONG - should be keepalived)
```

### After (FIXED)

```yaml
addresses:
  - 172.16.5.13/24 # Node IP only
# VIPs (172.16.5.2, 172.16.5.3) managed by keepalived
```

## Recovery Steps

If the node is locked out:

1. **Via console, remove VIP IPs from netplan files:**

   ```bash
   # Find netplan files with VIPs
   grep -l "172.16.*\.2\|172.16.*\.3" /etc/netplan/*.yaml

   # Edit each file and remove the .2 and .3 IPs
   sudo nano /etc/netplan/50-vlan-5-family.yaml
   # Remove lines with .2 or .3 IPs

   # Apply
   sudo netplan apply
   ```

2. **Or restore from backup:**

   ```bash
   # Netplan creates backups
   ls -la /etc/netplan/*.yaml.*

   # Restore
   sudo cp /etc/netplan/50-vlan-5-family.yaml.xxxxx /etc/netplan/50-vlan-5-family.yaml
   sudo netplan apply
   ```

3. **Verify only node IPs are configured:**
   ```bash
   ip addr show | grep -E "172\.16\.(5|15|101)\.(13|2)"
   # Should show only .13 (node IP), not .2 (VIP)
   ```

## After Recovery

Once the node is back online, the fixed Ansible playbook will:

- ✅ Only configure node IPs in netplan
- ✅ Let keepalived manage VIPs
- ✅ Not break network connectivity

Run the playbook again:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-become-pass
```
