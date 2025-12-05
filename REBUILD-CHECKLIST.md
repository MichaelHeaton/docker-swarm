# Node Rebuild Checklist - swarm-pi5-01

## Pre-Rebuild Checklist

### 1. Verify Ansible Configuration

- [x] VLAN 30 (storage) added to inventory
- [x] Storage role created
- [x] Storage role added to playbook
- [ ] Verify NAS01 NFS shares are created and accessible
- [ ] Test NFS connectivity from another node

### 2. Document Current State

- [ ] List all Docker volumes currently on swarm-pi5-01
- [ ] Document AdGuard configuration (if any custom settings)
- [ ] Note any custom network configurations

### 3. Backup (if needed)

- [ ] Export AdGuard configuration (if running)
- [ ] Note any custom Docker stack configurations

## Rebuild Steps

### Step 1: Reinstall OS

- [ ] Use image-factory to create/install OS
- [ ] Basic network connectivity working
- [ ] SSH access confirmed

### Step 2: Run Ansible Playbook

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml
```

This will:

- [ ] Configure all VLANs (5, 10, 15, 30, 40, 101)
- [ ] Set up IP addresses on each VLAN
- [ ] Configure AdGuard IPs (172.16.5.2, 172.16.15.2, 172.16.101.2)
- [ ] Install Docker
- [ ] Set up NFS mounts from NAS01
- [ ] Configure Docker Swarm

### Step 3: Verify Network Configuration

```bash
# Check all VLAN interfaces
ip addr show | grep -E "eth0\.(5|10|15|30|40|101)"

# Should see IPs on all VLANs:
# - eth0.5: 172.16.5.13/24 + 172.16.5.2/32 (AdGuard)
# - eth0.10: 172.16.10.13/24
# - eth0.15: 172.16.15.13/24 + 172.16.15.2/32 (AdGuard)
# - eth0.30: 172.16.30.13/24 (storage)
# - eth0.40: 172.16.40.13/24
# - eth0.101: 172.16.101.13/24 + 172.16.101.2/32 (AdGuard)

# Check routes (should be only ONE default route)
ip route show | grep default
# Should show: default via 172.16.15.1 dev eth0.15

# Test connectivity
ping -c 2 172.16.5.1    # Family VLAN
ping -c 2 172.16.15.1   # Management VLAN
ping -c 2 172.16.30.5   # NAS01 storage
```

### Step 4: Verify NFS Mounts

```bash
# Check mounts
mount | grep nfs

# Should see:
# 172.16.30.5:/volume1/docker/Configs on /mnt/nas/docker/configs
# 172.16.30.5:/volume1/docker/Volumes on /mnt/nas/docker/volumes
# 172.16.30.5:/volume1/docker/Logs on /mnt/nas/docker/logs
# 172.16.30.5:/volume1/docker/Secrets on /mnt/nas/docker/secrets
# 172.16.30.5:/volume1/docker/Backups on /mnt/nas/docker/backups

# Test write access
touch /mnt/nas/docker/volumes/test.txt
rm /mnt/nas/docker/volumes/test.txt
```

### Step 5: Rejoin Docker Swarm

```bash
# Get join token from another manager (swarm-pi5-02)
ssh swarm-pi5-02
docker swarm join-token manager

# Run on swarm-pi5-01
docker swarm join --token <token> 172.16.15.14:2377

# Verify node joined
docker node ls
```

### Step 6: Redeploy AdGuard

```bash
cd stacks
./adguard-standalone.sh

# Verify AdGuard is running
docker ps | grep adguard

# Test DNS
nslookup google.com 172.16.15.2
```

### Step 7: Update Docker Stacks to Use NAS Volumes

Update stack files to use bind mounts to NAS:

**Example for AdGuard:**

```yaml
volumes:
  adguard_work:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/nas/docker/volumes/adguard/work
  adguard_conf:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /mnt/nas/docker/volumes/adguard/conf
```

## Post-Rebuild Verification

- [ ] All VLAN interfaces have IPs
- [ ] Only one default route (via eth0.15)
- [ ] NFS mounts working and writable
- [ ] Docker Swarm node joined successfully
- [ ] AdGuard running and responding to DNS queries
- [ ] Services can access NAS storage
- [ ] Data persists after container restart

## Notes

- **VLAN 30** is storage-only - no default route needed
- **NAS01 IP**: 172.16.30.5 (storage VLAN)
- **NFS Shares**: /volume1/docker/\* on NAS01
- **Mount Points**: /mnt/nas/docker/\* on nodes
