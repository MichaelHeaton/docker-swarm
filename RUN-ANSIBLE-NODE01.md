# Run Ansible on swarm-pi5-01

## Command

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-become-pass
```

## What It Will Do

1. **Configure all VLANs** (5, 10, 15, 20, 30, 40, 101, 200)
2. **Set up IP addresses** on each VLAN interface
3. **Configure AdGuard VIPs** (.2 IPs) via keepalived
4. **Configure Traefik VIPs** (.3 IPs) via keepalived
5. **Set up NFS mounts** from NAS01 (172.16.30.5)
6. **Install Docker**
7. **Configure Docker Swarm** (if first node)

## When Prompted

- **BECOME password**: Enter the `packer` user's sudo password (same as SSH password)

## After It Completes

Verify everything worked:

```bash
# Check VLAN IPs
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "ip addr show | grep -E 'eth0\.(5|10|15|20|30|40|101|200)' | grep 'inet '"

# Check routes (should be only ONE default route)
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "ip route show | grep default"

# Check VIPs
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "ip addr show | grep -E '172\.16\.(5|15|101|40)\.(2|3)'"

# Check NFS mounts
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13 "mount | grep nfs"
```

## If It Fails

Check the error message and:

- Network issues: Check VLAN configuration
- VIP issues: Check keepalived logs
- NFS issues: Check connectivity to NAS (172.16.30.5)
