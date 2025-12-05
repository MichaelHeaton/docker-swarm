# Virtual IP (VIP) Setup Summary

## Problem Solved

**Before**: DNS hardcoded to `172.16.15.13` (swarm-pi5-01) - single point of failure
**After**: DNS uses floating VIPs (`172.16.5.2`, `172.16.15.2`, `172.16.101.2`) that move between nodes

## How It Works

1. **Keepalived** provides Virtual IPs (VIPs) that float between nodes
2. **Primary node** (swarm-pi5-01) holds VIPs with highest priority (110)
3. **Backup nodes** (swarm-pi5-02, swarm-pi5-03) can take over with lower priorities (100, 90)
4. **Health check** monitors DNS service - if it fails, VIP moves to backup
5. **DNS records** point to VIPs, not specific node IPs

## VIP Configuration

### VIP IPs (Same as AdGuard IPs, but now floating)

- **VLAN 5 (Family)**: `172.16.5.2` - Floats between nodes
- **VLAN 15 (Management)**: `172.16.15.2` - Floats between nodes
- **VLAN 101 (Guest)**: `172.16.101.2` - Floats between nodes

### Node Priorities

- **swarm-pi5-01**: Priority 110 (MASTER) - Primary holder of VIPs
- **swarm-pi5-02**: Priority 100 (BACKUP) - Takes over if primary fails
- **swarm-pi5-03**: Priority 90 (BACKUP) - Takes over if both others fail

## What Changed

### Ansible Configuration

1. ✅ **Keepalived role created** - Manages VIP failover
2. ✅ **Inventory updated** - Priorities and states configured
3. ✅ **VIP IPs defined** - Same IPs as AdGuard, but now floating
4. ✅ **Playbook updated** - Keepalived role added

### DNS Configuration (After Deployment)

**Update DNS records to use VIPs:**

- `blocker.specterrealm.com` → `172.16.5.2` (VIP, not `172.16.15.13`)
- `adguard-mgmt.specterrealm.com` → `172.16.15.2` (VIP, not `172.16.15.13`)

**Update DHCP DNS settings:**

- VLAN 5: Primary DNS → `172.16.5.2` (VIP)
- VLAN 101: Primary DNS → `172.16.101.2` (VIP)
- VLAN 15: Primary DNS → `172.16.15.2` (VIP)

## Deployment

### During Rebuild

Keepalived will be automatically deployed when you run:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml
```

### After Rebuild

1. **Verify VIPs are active:**

   ```bash
   # On swarm-pi5-01 (should have VIPs)
   ip addr show eth0.5 | grep 172.16.5.2
   ip addr show eth0.15 | grep 172.16.15.2
   ip addr show eth0.101 | grep 172.16.101.2
   ```

2. **Test failover:**

   ```bash
   # Stop AdGuard on primary
   docker stop adguard

   # Watch VIP move (within 5-10 seconds)
   # Check backup node
   ssh swarm-pi5-02
   ip addr show eth0.15 | grep 172.16.15.2
   ```

3. **Update DNS records** in UniFi Controller to point to VIPs

## Benefits

✅ **High Availability** - DNS survives node failures
✅ **No Hardcoded IPs** - DNS points to VIPs, not node IPs
✅ **Automatic Failover** - VIP moves automatically when node fails
✅ **Health Monitoring** - Keepalived checks DNS service health
✅ **Transparent** - Clients don't need configuration changes

## Important Notes

1. **AdGuard must be running** on the node that holds the VIP

   - If primary fails, deploy AdGuard on backup node
   - Or deploy AdGuard on multiple nodes for true HA

2. **VIPs use same IPs as AdGuard**

   - We're reusing `.2` IPs but making them floating
   - No need to change DNS records (just point to same IPs)

3. **Keepalived password** should be stored in Ansible Vault
   - Currently using default - update before production use

## Next Steps

1. ✅ Keepalived role created
2. ✅ Inventory configured
3. ⏳ Deploy during node rebuild
4. ⏳ Verify VIPs working
5. ⏳ Test failover
6. ⏳ Update DNS records (if needed - IPs are the same)
7. ⏳ Consider deploying AdGuard on multiple nodes
