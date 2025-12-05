# Netplan Recovery Guide

## Situation

Nodes swarm-pi5-01, swarm-pi5-03, and swarm-pi5-04 are unreachable via SSH due to a Netplan configuration issue. The Ansible playbook added default routes to all VLAN interfaces, causing routing conflicts.

## Root Cause

The Netplan template incorrectly added a default route (`to: 0.0.0.0/0`) to **every VLAN interface**. Only the management VLAN (VLAN 15) should have a default route. Multiple default routes cause routing conflicts and break connectivity.

## Recovery Steps

### Step 1: Get Console Access

1. Physically access each affected node (swarm-pi5-01, swarm-pi5-03, swarm-pi5-04)
2. Connect a monitor and keyboard
3. Boot the node (if powered off) or log in to the console

### Step 2: Transfer Recovery Script

**Option A: Copy script via USB**

1. Copy `netplan-recovery.sh` to a USB drive
2. Insert USB into the node
3. Mount and copy the script:
   ```bash
   sudo mkdir -p /mnt/usb
   sudo mount /dev/sda1 /mnt/usb  # Adjust device as needed
   cp /mnt/usb/netplan-recovery.sh ~/
   chmod +x ~/netplan-recovery.sh
   ```

**Option B: Manual fix (if you can't transfer the script)**
See "Manual Fix Steps" below.

### Step 3: Run Recovery Script

```bash
cd ~
./netplan-recovery.sh
```

Or if you need to download it:

```bash
# If you have internet access on the node
wget https://raw.githubusercontent.com/your-repo/docker-swarm/netplan-recovery.sh
chmod +x netplan-recovery.sh
./netplan-recovery.sh
```

### Step 4: Verify Connectivity

After running the script:

```bash
# Check routes
ip route show

# Should see only ONE default route:
# default via 172.16.15.1 dev eth0.15

# Test SSH (from another machine)
ssh packer@172.16.15.13  # For swarm-pi5-01
ssh packer@172.16.15.15  # For swarm-pi5-03
ssh packer@172.16.15.16  # For swarm-pi5-04
```

## Manual Fix Steps (If Script Doesn't Work)

If you can't use the recovery script, manually edit each Netplan file:

### 1. Fix VLAN 5 (Family)

```bash
sudo nano /etc/netplan/50-vlan-5-family.yaml
```

Remove these lines:

```yaml
routes:
  - to: 0.0.0.0/0
    via: 172.16.5.1
```

Keep only:

```yaml
addresses:
  - 172.16.5.X/24 # Node IP
  - 172.16.5.2/32 # AdGuard IP (only on swarm-pi5-01)
nameservers:
  addresses:
    - 172.16.15.1
    - 1.1.1.1
```

### 2. Fix VLAN 10 (Production)

```bash
sudo nano /etc/netplan/50-vlan-10-production.yaml
```

Remove the `routes:` section (same as above).

### 3. Fix VLAN 40 (DMZ)

```bash
sudo nano /etc/netplan/50-vlan-40-dmz.yaml
```

Remove the `routes:` section.

### 4. Fix VLAN 101 (Guest)

```bash
sudo nano /etc/netplan/50-vlan-101-guest.yaml
```

Remove the `routes:` section.

### 5. Keep VLAN 15 (Management) As-Is

**DO NOT** modify `/etc/netplan/50-vlan-15-mgmt.yaml` - it should keep its default route.

### 6. Apply Changes

```bash
# Validate first
sudo netplan --debug generate

# Apply
sudo netplan apply
```

## Quick One-Liner Fix (If You Have Console Access)

If you just need to quickly fix it:

```bash
# Remove routes from all non-management VLANs
for file in /etc/netplan/50-vlan-{5-family,10-production,40-dmz,101-guest}.yaml; do
    [ -f "$file" ] && sudo sed -i '/routes:/,/via:/d' "$file"
done

# Apply
sudo netplan apply
```

## After Recovery

Once connectivity is restored:

1. **Verify all nodes are reachable:**

   ```bash
   for node in 13 14 15 16; do
       echo "Testing 172.16.15.$node..."
       ssh -o ConnectTimeout=5 packer@172.16.15.$node "hostname" || echo "Failed"
   done
   ```

2. **Re-run Ansible with the fixed template:**

   ```bash
   cd ansible
   ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network
   ```

   The template has been fixed to only add default routes to VLAN 15.

3. **Verify services are running:**

   ```bash
   # Check Docker Swarm
   docker node ls

   # Check services
   docker service ls
   ```

## Prevention

The Netplan template has been fixed to only add default routes to VLAN 15 (management). Future Ansible runs will not cause this issue.

## Files Modified

- ✅ `ansible/roles/network/templates/netplan-vlan.yaml.j2` - Fixed to only add routes to VLAN 15
- ✅ `netplan-recovery.sh` - Recovery script
- ✅ `NETPLAN-RECOVERY-GUIDE.md` - This guide

## Summary

**The Problem:** Default routes on all VLANs caused routing conflicts.

**The Fix:** Remove default routes from VLANs 5, 10, 40, and 101. Keep only VLAN 15 with a default route.

**The Solution:** Run the recovery script on each affected node via console access.

