# AdGuard IP Configuration via Ansible

## Overview

The AdGuard Home IP aliases (`.2` IPs on VLANs 5, 101, and 15) are now **automatically managed by Ansible** instead of manual Netplan edits. This ensures:

- ✅ Configuration is version-controlled
- ✅ Consistent across all nodes
- ✅ Persistent across reboots
- ✅ No manual intervention required

## Changes Made

### 1. Inventory Updates (`ansible/inventory/swarm-pi5.yml`)

**Added `runs_adguard` flag to swarm-pi5-01:**

```yaml
swarm-pi5-01:
  # ... existing config ...
  runs_adguard: true # This node runs AdGuard Home
```

**Added `adguard_ip` to VLAN definitions:**

```yaml
swarm_vlans:
  - id: 5
    name: family
    subnet: 172.16.5.0/24
    adguard_ip: 172.16.5.2/32 # Dedicated AdGuard DNS IP
  - id: 101
    name: guest
    subnet: 172.16.101.0/24
    adguard_ip: 172.16.101.2/32
  - id: 15
    name: mgmt
    subnet: 172.16.15.0/24
    adguard_ip: 172.16.15.2/32
```

### 2. Network Role Updates (`ansible/roles/network/tasks/main.yml`)

The network role now:

1. **Extracts node number** from `static_ip` (e.g., `13` from `172.16.15.13/24`)
2. **Calculates node IP** for each VLAN (e.g., `172.16.5.13/24` for VLAN 5)
3. **Adds AdGuard IP** to Netplan if:
   - Node has `runs_adguard: true`
   - VLAN has `adguard_ip` defined

**Generated Netplan Example** (for swarm-pi5-01 on VLAN 5):

```yaml
network:
  version: 2
  vlans:
    eth0.5:
      id: 5
      link: eth0
      dhcp4: false
      addresses:
        - 172.16.5.13/24 # Node IP on this VLAN
        - 172.16.5.2/32 # AdGuard Home dedicated DNS IP
      routes:
        - to: 0.0.0.0/0
          via: 172.16.5.1
      nameservers:
        addresses:
          - 172.16.15.1
          - 1.1.1.1
```

## Usage

### Apply Configuration

To apply the network configuration (including AdGuard IPs):

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network
```

Or run the full playbook:

```bash
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml
```

### Verify Configuration

After running Ansible, verify on `swarm-pi5-01`:

```bash
# Check Netplan files
ls -la /etc/netplan/50-vlan-*.yaml

# View VLAN 5 config
cat /etc/netplan/50-vlan-5-family.yaml

# Verify IP addresses are configured
ip addr show eth0.5 | grep "172.16.5"
# Should show both 172.16.5.13 and 172.16.5.2

ip addr show eth0.101 | grep "172.16.101"
# Should show both 172.16.101.13 and 172.16.101.2

ip addr show eth0.15 | grep "172.16.15"
# Should show both 172.16.15.13 and 172.16.15.2
```

## Benefits

1. **Version Control**: All network configuration is in Git
2. **Idempotent**: Running Ansible multiple times is safe
3. **Consistent**: Same configuration method for all nodes
4. **Maintainable**: Changes are made in one place (inventory)
5. **Documented**: Configuration is self-documenting in YAML

## Migration Notes

If you previously configured AdGuard IPs manually:

1. **Remove manual Netplan edits** - They will be overwritten by Ansible
2. **Run Ansible** to apply the new configuration
3. **Verify** IPs are correctly configured

The manual `ip addr add` commands are no longer needed - Ansible handles everything.

## Adding AdGuard to Another Node

To run AdGuard on a different node:

1. **Add `runs_adguard: true`** to that node in inventory
2. **Run Ansible** network role
3. **Deploy AdGuard** to that node

The Netplan configuration will automatically include the AdGuard IPs.

## Troubleshooting

### IPs Not Appearing

1. **Check inventory**: Ensure `runs_adguard: true` is set on the correct node
2. **Check VLAN config**: Ensure `adguard_ip` is defined for the VLAN
3. **Run Ansible**: Apply the network role
4. **Check Netplan**: Verify the generated YAML includes the AdGuard IP
5. **Apply Netplan**: `sudo netplan apply` (if Ansible didn't do it)

### IPs Disappear After Reboot

If IPs disappear after reboot, the Netplan configuration may not have been applied. Run:

```bash
sudo netplan apply
```

Or re-run Ansible to regenerate and apply the configuration.

## Related Files

- `ansible/inventory/swarm-pi5.yml` - Inventory with AdGuard configuration
- `ansible/roles/network/tasks/main.yml` - Network role that generates Netplan
- `ADGUARD-DNS-UPDATE-CHECKLIST.md` - DNS update checklist
- `ADGUARD-MULTI-VLAN-IMPLEMENTATION.md` - Implementation guide
