# Node Rebuild Plan - swarm-pi5-01

## Overview

This plan ensures the node is properly configured with:

1. IP addresses on ALL VLANs (including storage VLAN 30)
2. NFS mounts from NAS01 for persistent Docker data
3. Proper Docker volume configuration to use NAS storage

## Step 1: Add Storage VLAN (30) to Ansible Configuration

### Update Inventory

Add VLAN 30 to `ansible/inventory/swarm-pi5.yml`:

```yaml
swarm_vlans:
  - id: 5
    name: family
    subnet: 172.16.5.0/24
    adguard_ip: 172.16.5.2/32
  - id: 10
    name: production
    subnet: 172.16.10.0/24
  - id: 15
    name: mgmt
    subnet: 172.16.15.0/24
    adguard_ip: 172.16.15.2/32
  - id: 30
    name: storage
    subnet: 172.16.30.0/24
  - id: 40
    name: dmz
    subnet: 172.16.40.0/24
  - id: 101
    name: guest
    subnet: 172.16.101.0/24
    adguard_ip: 172.16.101.2/32
```

**Note**: VLAN 30 should NOT have a default route - it's storage-only.

## Step 2: Create Ansible Role for NFS Mounts

### Create Storage Role

Create `ansible/roles/storage/tasks/main.yml`:

```yaml
---
# Storage Configuration - NFS Mounts for Docker Volumes

- name: Install NFS client utilities
  ansible.builtin.apt:
    name:
      - nfs-common
    state: present
    update_cache: true

- name: Create NFS mount points
  ansible.builtin.file:
    path: "{{ item }}"
    state: directory
    mode: "0755"
    owner: root
    group: root
  loop:
    - /mnt/nas/docker/configs
    - /mnt/nas/docker/volumes
    - /mnt/nas/docker/logs
    - /mnt/nas/docker/secrets
    - /mnt/nas/docker/backups

- name: Configure NFS mounts in /etc/fstab
  ansible.builtin.lineinfile:
    path: /etc/fstab
    line: "{{ item.server }}:{{ item.remote_path }} {{ item.local_path }} nfs4 defaults,_netdev,noauto 0 0"
    create: true
    state: present
  loop:
    - {
        server: "172.16.30.5",
        remote_path: "/volume1/docker/Configs",
        local_path: "/mnt/nas/docker/configs",
      }
    - {
        server: "172.16.30.5",
        remote_path: "/volume1/docker/Volumes",
        local_path: "/mnt/nas/docker/volumes",
      }
    - {
        server: "172.16.30.5",
        remote_path: "/volume1/docker/Logs",
        local_path: "/mnt/nas/docker/logs",
      }
    - {
        server: "172.16.30.5",
        remote_path: "/volume1/docker/Secrets",
        local_path: "/mnt/nas/docker/secrets",
      }
    - {
        server: "172.16.30.5",
        remote_path: "/volume1/docker/Backups",
        local_path: "/mnt/nas/docker/backups",
      }

- name: Mount NFS shares
  ansible.builtin.mount:
    path: "{{ item }}"
    src: "{{ item.split('/')[-1] }}"
    fstype: nfs4
    state: mounted
    opts: defaults,_netdev
  loop:
    - /mnt/nas/docker/configs
    - /mnt/nas/docker/volumes
    - /mnt/nas/docker/logs
    - /mnt/nas/docker/secrets
    - /mnt/nas/docker/backups
```

**Note**: Update `172.16.30.5` with the actual NAS01 storage IP if different.

## Step 3: Update Docker Configuration

### Configure Docker to Use NAS for Volumes

Update `ansible/roles/docker/tasks/main.yml` to configure Docker daemon:

```yaml
- name: Configure Docker to use NAS storage for volumes
  ansible.builtin.lineinfile:
    path: /etc/docker/daemon.json
    regexp: '^  "data-root":'
    line: '  "data-root": "/mnt/nas/docker/volumes",'
    insertafter: "{"
    create: true
  when: docker_daemon_config is defined
```

**OR** use Docker volume plugins/drivers to mount NAS volumes.

## Step 4: Rebuild Process

### 1. Reinstall OS

- Use your image-factory process
- Standard Ubuntu/Raspberry Pi OS installation

### 2. Run Full Ansible Playbook

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml
```

This will:

- ✅ Configure all VLANs (5, 10, 15, 30, 40, 101)
- ✅ Set up IP addresses on each VLAN
- ✅ Configure AdGuard IPs on swarm-pi5-01
- ✅ Install Docker
- ✅ Set up NFS mounts
- ✅ Configure Docker Swarm

### 3. Verify Network Configuration

```bash
# Check all VLAN interfaces
ip addr show | grep -E "eth0\.(5|10|15|30|40|101)"

# Check routes (should be only one default route)
ip route show | grep default

# Test connectivity to each VLAN
ping -c 2 172.16.5.1
ping -c 2 172.16.15.1
ping -c 2 172.16.30.5  # NAS storage IP
```

### 4. Verify NFS Mounts

```bash
# Check mounts
mount | grep nfs

# Test write access
touch /mnt/nas/docker/volumes/test.txt
rm /mnt/nas/docker/volumes/test.txt
```

### 5. Rejoin Docker Swarm

```bash
# Get join token from another manager
docker swarm join-token manager

# Run on swarm-pi5-01
docker swarm join --token <token> <manager-ip>:2377
```

### 6. Redeploy AdGuard

```bash
cd stacks
./adguard-standalone.sh
```

## Step 5: Update Docker Stack Volumes

### Update Volume Definitions

Update stack files to use NAS-mounted volumes:

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

## Checklist

Before Rebuild:

- [ ] Add VLAN 30 to Ansible inventory
- [ ] Create storage role for NFS mounts
- [ ] Verify NAS01 NFS shares are configured
- [ ] Get NAS01 storage IP address (172.16.30.x)
- [ ] Document current Docker volumes to migrate

During Rebuild:

- [ ] Reinstall OS
- [ ] Run Ansible playbook
- [ ] Verify all VLAN IPs configured
- [ ] Verify NFS mounts working
- [ ] Rejoin Docker Swarm
- [ ] Redeploy services

After Rebuild:

- [ ] Verify services running
- [ ] Test data persistence (restart containers)
- [ ] Verify AdGuard working
- [ ] Check Docker volumes on NAS

## Questions to Answer

1. **NAS01 Storage IP**: What is the actual IP of NAS01 on VLAN 30?
2. **NFS Shares**: Are the Docker shares already created on NAS01?
3. **Existing Volumes**: Do we need to migrate existing Docker volumes?
4. **Volume Strategy**: Use bind mounts or Docker volume driver?

## Next Steps

1. Confirm NAS01 storage IP
2. Verify NFS shares exist on NAS01
3. Create/update Ansible storage role
4. Test on one node before rebuilding swarm-pi5-01
