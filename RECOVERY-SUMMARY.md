# Node Recovery Summary

## Current Status

- ✅ **swarm-pi5-02**: Fixed and working
- ❌ **swarm-pi5-01**: Needs recovery (172.16.15.13)
- ❌ **swarm-pi5-03**: Needs recovery (172.16.15.15)
- ❌ **swarm-pi5-04**: Needs recovery (172.16.15.16)

## Quick Recovery (Per Node)

### Option 1: One-Liner (Fastest)

Copy and paste this on each node via console:

```bash
for file in /etc/netplan/50-vlan-{5-family,10-production,40-dmz,101-guest}.yaml /etc/netplan/00-installer-config.yaml; do [ -f "$file" ] && sudo sed -i '/routes:/,/via:/d' "$file"; done && sudo netplan apply && echo "✅ Fixed!"
```

### Option 2: Recovery Script

1. Copy `netplan-recovery.sh` to USB drive
2. On each node:
   ```bash
   sudo mount /dev/sda1 /mnt
   cp /mnt/netplan-recovery.sh ~/
   chmod +x ~/netplan-recovery.sh
   ./netplan-recovery.sh
   ```

### Option 3: Manual Steps

See `NODE-RECOVERY-STEPS.md` for detailed manual steps.

## Verification (After Fix)

```bash
# Should show only ONE default route:
ip route show | grep default

# Should ping gateway:
ping -c 3 172.16.15.1

# Test SSH from your machine:
ssh packer@172.16.15.13  # swarm-pi5-01
ssh packer@172.16.15.15  # swarm-pi5-03
ssh packer@172.16.15.16  # swarm-pi5-04
```

## What the Fix Does

Removes default routes from:

- VLAN 5 (Family)
- VLAN 10 (Production)
- VLAN 40 (DMZ)
- VLAN 101 (Guest)
- Primary eth0 interface

Keeps default route only on:

- VLAN 15 (Management) - via eth0.15

## After All Nodes Recovered

1. Verify all nodes accessible
2. Re-run Ansible (template is fixed)
3. Verify Docker Swarm cluster

See `NODE-RECOVERY-STEPS.md` for complete details.
