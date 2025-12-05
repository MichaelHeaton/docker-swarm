# Node Recovery Steps - swarm-pi5-01, swarm-pi5-03, swarm-pi5-04

## Overview

These nodes have routing conflicts due to multiple default routes. Follow these steps to recover each node.

## Prerequisites

- Physical/console access to each node
- USB drive (optional, for transferring recovery script)
- Keyboard and monitor (or serial console)

## Recovery Steps (Per Node)

### Step 1: Access the Node

1. **Power on the node** (if off) or connect via console
2. **Log in** with your credentials (usually `packer` user)
3. **Switch to root** if needed: `sudo su -`

### Step 2: Fix Netplan Configuration

Run these commands **on each affected node** (swarm-pi5-01, swarm-pi5-03, swarm-pi5-04):

```bash
# Remove default routes from non-management VLANs
sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-5-family.yaml
sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-10-production.yaml
sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-40-dmz.yaml
sudo sed -i '/routes:/,/via:/d' /etc/netplan/50-vlan-101-guest.yaml

# Remove default route from primary eth0 interface (if it exists)
sudo sed -i '/routes:/,/via:/d' /etc/netplan/00-installer-config.yaml

# Validate the configuration
sudo netplan --debug generate

# Apply the fix
sudo netplan apply
```

### Step 3: Verify Routing

```bash
# Check routes - should see only ONE default route via 172.16.15.1
ip route show | grep default

# Expected output:
# default via 172.16.15.1 dev eth0.15 proto static
```

### Step 4: Test Connectivity

```bash
# Test gateway connectivity
ping -c 3 172.16.15.1

# Test SSH from another machine (after a few seconds)
# From your local machine:
ssh packer@172.16.15.13  # For swarm-pi5-01
ssh packer@172.16.15.15  # For swarm-pi5-03
ssh packer@172.16.15.16  # For swarm-pi5-04
```

### Step 5: Verify Services

Once SSH is working, verify Docker and services:

```bash
# Check Docker status
sudo systemctl status docker

# Check Docker Swarm
docker node ls

# Check services
docker service ls
```

## Alternative: Using Recovery Script

If you transferred `netplan-recovery.sh` to a USB drive:

```bash
# Mount USB (adjust device as needed)
sudo mkdir -p /mnt/usb
sudo mount /dev/sda1 /mnt/usb  # Check with: lsblk

# Copy and run
cp /mnt/usb/netplan-recovery.sh ~/
chmod +x ~/netplan-recovery.sh
./netplan-recovery.sh
```

## Node-Specific IPs

- **swarm-pi5-01**: 172.16.15.13
- **swarm-pi5-03**: 172.16.15.15
- **swarm-pi5-04**: 172.16.15.16

## Quick Reference Commands

**One-liner fix (copy/paste):**

```bash
for file in /etc/netplan/50-vlan-{5-family,10-production,40-dmz,101-guest}.yaml /etc/netplan/00-installer-config.yaml; do [ -f "$file" ] && sudo sed -i '/routes:/,/via:/d' "$file"; done && sudo netplan apply && echo "✅ Fixed! Check routes: ip route show | grep default"
```

## Troubleshooting

### If netplan apply fails:

```bash
# Check for syntax errors
sudo netplan --debug generate

# View the error messages
# Common issues:
# - File permissions (should be 600)
# - YAML syntax errors
# - Conflicting routes
```

### If still can't SSH after fix:

1. **Check routes again:**

   ```bash
   ip route show
   ```

2. **Check interface status:**

   ```bash
   ip addr show eth0.15
   ```

3. **Check gateway:**

   ```bash
   ping -c 3 172.16.15.1
   ```

4. **Check firewall:**
   ```bash
   sudo ufw status
   ```

### If Docker won't start:

This is a separate issue. Check Docker logs:

```bash
sudo journalctl -u docker.service -n 50
```

## After All Nodes Are Recovered

1. **Verify all nodes are accessible:**

   ```bash
   for node in 13 14 15 16; do
       echo "Testing 172.16.15.$node..."
       ssh -o ConnectTimeout=5 packer@172.16.15.$node "hostname && echo '✅ OK'" || echo "❌ Failed"
   done
   ```

2. **Re-run Ansible with fixed template:**

   ```bash
   cd ansible
   ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network
   ```

   The template is now fixed to only add default routes to VLAN 15.

3. **Verify Docker Swarm:**
   ```bash
   ssh swarm-pi5-01 "docker node ls"
   ```

## Checklist

For each node (swarm-pi5-01, swarm-pi5-03, swarm-pi5-04):

- [ ] Console access obtained
- [ ] Netplan files fixed (removed routes from VLANs 5, 10, 40, 101)
- [ ] Primary interface fixed (removed route from eth0)
- [ ] Netplan applied successfully
- [ ] Only one default route (via 172.16.15.1 on eth0.15)
- [ ] Gateway pingable (172.16.15.1)
- [ ] SSH accessible from remote machine
- [ ] Docker service running (if applicable)
- [ ] Node appears in `docker node ls`

## Notes

- **swarm-pi5-02** is already fixed and working ✅
- The fix removes default routes from all VLANs except VLAN 15 (management)
- This matches the corrected Ansible template behavior
- After recovery, re-running Ansible is safe (template is fixed)

