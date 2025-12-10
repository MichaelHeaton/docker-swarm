# Phase 1 Troubleshooting Guide

## Issue: Services Showing 0/1 Replicas

If Prowlarr or SABnzbd show `0/1` replicas, the services aren't starting. Here's how to diagnose:

## Diagnostic Commands

Run these commands on the Docker Swarm manager node:

### 1. Check Service Status

```bash
ssh packer@swarm-pi5-01.specterrealm.com
docker service ls | grep -E "prowlarr|sabnzbd"
```

### 2. Check Service Tasks (Detailed Status)

```bash
# Check Prowlarr task status
docker service ps prowlarr_prowlarr --no-trunc

# Check SABnzbd task status
docker service ps sabnzbd_sabnzbd --no-trunc
```

This will show **why** the tasks are failing (e.g., "no suitable node", "mount error", etc.)

### 3. Check Service Logs

```bash
# Prowlarr logs
docker service logs prowlarr_prowlarr --tail 50

# SABnzbd logs
docker service logs sabnzbd_sabnzbd --tail 50
```

### 4. Check NFS Mounts

```bash
# Verify NFS mounts exist
ls -la /mnt/nas/dockers
ls -la /mnt/nas/media_streaming

# Check mount status
mount | grep nfs
```

### 5. Check Network

```bash
# Verify mgmt-network exists
docker network ls | grep mgmt-network
```

### 6. Check Folder Permissions

```bash
# Check if folders exist and have correct permissions
ls -la /mnt/nas/dockers/prowlarr
ls -la /mnt/nas/dockers/sabnzbd
ls -la /mnt/nas/media_streaming/downloads
```

## Common Issues and Fixes

### Issue 1: NFS Mounts Not Available

**Symptoms**: Tasks fail with "mount error" or "no such file or directory"

**Fix**:

```bash
# Check if NFS mounts are configured
cat /etc/fstab | grep nfs

# If missing, run Ansible storage role
# Or manually mount:
sudo mount -t nfs -o vers=3 172.16.30.4:/var/nfs/shared/dockers /mnt/nas/dockers
sudo mount -t nfs -o vers=3 172.16.30.4:/var/nfs/shared/media_streaming /mnt/nas/media_streaming
```

### Issue 2: Missing Folders

**Symptoms**: Tasks fail with "no such file or directory" for config or download folders

**Fix**:

```bash
# Create required folders
sudo mkdir -p /mnt/nas/dockers/prowlarr/config
sudo mkdir -p /mnt/nas/dockers/sabnzbd/config
sudo mkdir -p /mnt/nas/media_streaming/downloads/{usenet,completed,incomplete,processed}

# Set permissions
sudo chown -R 1000:1000 /mnt/nas/dockers/prowlarr
sudo chown -R 1000:1000 /mnt/nas/dockers/sabnzbd
sudo chown -R 1000:1000 /mnt/nas/media_streaming
```

### Issue 3: Network Not Found

**Symptoms**: Tasks fail with "network mgmt-network not found"

**Fix**:

```bash
# Check if network exists
docker network ls | grep mgmt-network

# If missing, check Traefik stack (it creates mgmt-network)
docker stack ls
docker stack services traefik
```

### Issue 4: No Suitable Node

**Symptoms**: Tasks show "no suitable node" error

**Fix**:

```bash
# Check node constraints
docker node ls

# Verify manager nodes are available
docker node ls | grep Leader
```

### Issue 5: Permission Denied

**Symptoms**: Tasks fail with "permission denied" errors

**Fix**:

```bash
# Fix folder ownership (UID/GID 1000 for Hotio containers)
sudo chown -R 1000:1000 /mnt/nas/dockers/prowlarr
sudo chown -R 1000:1000 /mnt/nas/dockers/sabnzbd
sudo chown -R 1000:1000 /mnt/nas/media_streaming

# Check NFS export permissions on NAS
# Ensure root_squash is configured correctly
```

## Quick Fix Script

Run this to fix common issues:

```bash
#!/bin/bash
# Fix common Phase 1 deployment issues

# Create folders
sudo mkdir -p /mnt/nas/dockers/prowlarr/config
sudo mkdir -p /mnt/nas/dockers/sabnzbd/config
sudo mkdir -p /mnt/nas/media_streaming/downloads/{usenet,completed,incomplete,processed}

# Set permissions
sudo chown -R 1000:1000 /mnt/nas/dockers/prowlarr
sudo chown -R 1000:1000 /mnt/nas/dockers/sabnzbd
sudo chown -R 1000:1000 /mnt/nas/media_streaming

# Verify mounts
echo "Checking NFS mounts..."
mount | grep nfs

# Restart services
docker service update --force prowlarr_prowlarr
docker service update --force sabnzbd_sabnzbd

# Check status
sleep 5
docker service ls | grep -E "prowlarr|sabnzbd"
```

## After Fixing

Once services show `1/1` replicas:

1. **Verify Access**:

   - Prowlarr: `https://prowlarr.specterrealm.com`
   - SABnzbd: `https://sabnzbd.specterrealm.com`

2. **Check Logs**:

   ```bash
   docker service logs -f prowlarr_prowlarr
   docker service logs -f sabnzbd_sabnzbd
   ```

3. **Proceed with Configuration** (see `DEPLOY-STREAMING-PHASE1.md`)
