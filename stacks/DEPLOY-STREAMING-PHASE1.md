# Streaming Stack Phase 1 Deployment Guide

## Overview

This guide walks through deploying Phase 1 foundation services: **Prowlarr** and **SABnzbd**.

## Prerequisites

### 1. Verify NFS Mounts

Ensure NFS mounts are configured on Docker Swarm manager nodes:

```bash
# SSH to a Docker Swarm manager node
ssh packer@swarm-pi5-01.specterrealm.com

# Check if mounts exist
ls -la /mnt/nas/dockers
ls -la /mnt/nas/media_streaming

# Check mount status
mount | grep nfs
```

**Expected mounts:**

- `/mnt/nas/dockers` → NAS02 `/var/nfs/shared/dockers`
- `/mnt/nas/media_streaming` → NAS02 `/var/nfs/shared/media_streaming`

**If mounts are missing**, run the Ansible storage role:

```bash
cd /Users/michaelheaton/Projects/HomeLab/docker-swarm/ansible
ansible-playbook playbooks/configure-storage.yml
```

### 2. Create Folder Structure

Create the required folder structure on the streaming share:

```bash
# On Docker Swarm manager node
sudo mkdir -p /mnt/nas/media_streaming/downloads/{usenet,completed,incomplete,processed}
sudo mkdir -p /mnt/nas/media_streaming/{movies,series}
sudo mkdir -p /mnt/nas/media_streaming/metadata/{sonarr,radarr,bazarr}
sudo mkdir -p /mnt/nas/media_streaming/transcoding

# Set permissions (adjust UID/GID if needed)
sudo chown -R 1000:1000 /mnt/nas/media_streaming
sudo chmod -R 755 /mnt/nas/media_streaming
```

**Note**: UID/GID 1000 is the default for Hotio containers (PUID=1000, PGID=1000).

## Deployment Steps

### Step 1: Deploy Prowlarr

```bash
# From docker-swarm directory
cd /Users/michaelheaton/Projects/HomeLab/docker-swarm

# Deploy Prowlarr
docker stack deploy -c stacks/prowlarr.yml prowlarr

# Verify deployment
docker service ls | grep prowlarr
docker service logs -f prowlarr_prowlarr
```

**Access**: `https://prowlarr.specterrealm.com` (admin VLANs only)

### Step 2: Deploy SABnzbd

```bash
# Deploy SABnzbd
docker stack deploy -c stacks/sabnzbd.yml sabnzbd

# Verify deployment
docker service ls | grep sabnzbd
docker service logs -f sabnzbd_sabnzbd
```

**Access**: `https://sabnzbd.specterrealm.com` (admin VLANs only)

## Configuration

### Prowlarr Configuration

1. **Access Prowlarr**: `https://prowlarr.specterrealm.com`
2. **Initial Setup**:
   - Set admin username/password
   - Configure timezone
3. **Add Indexers**:
   - Go to **Settings** → **Indexers**
   - Click **Add Indexer**
   - Add your Usenet providers (e.g., Newshosting, UsenetServer, etc.)
   - Test each indexer connection
4. **Configure Categories** (for Sonarr/Radarr integration):
   - **TV**: Category 5000
   - **Movies**: Category 2000
   - These will be used by Sonarr/Radarr later

### SABnzbd Configuration

1. **Access SABnzbd**: `https://sabnzbd.specterrealm.com`
2. **Initial Setup Wizard**:
   - Complete the setup wizard
   - Set download paths:
     - **Temporary Download Folder**: `/data/downloads` (maps to `/mnt/nas/media_streaming/downloads/usenet`)
     - **Completed Download Folder**: `/data/completed` (maps to `/mnt/nas/media_streaming/downloads/completed`)
     - **Incomplete Downloads Folder**: `/data/incomplete` (maps to `/mnt/nas/media_streaming/downloads/incomplete`)
3. **Configure Usenet Servers**:
   - Go to **Config** → **Servers**
   - Add your Usenet provider(s)
   - Test connection
4. **Configure Categories**:
   - Go to **Config** → **Categories**
   - **TV**: Category `tv` → Path: `/data/completed/tv`
   - **Movies**: Category `movies` → Path: `/data/completed/movies`
   - These categories will be used by Sonarr/Radarr
5. **Connect to Prowlarr** (optional, but recommended):
   - Go to **Config** → **Switches**
   - Enable **Enable API Key**
   - Note the API key
   - In Prowlarr, go to **Settings** → **Download Clients** → **Add Download Client** → **SABnzbd**
   - Enter SABnzbd URL: `http://sabnzbd:8080` (internal Docker network)
   - Or use external URL: `https://sabnzbd.specterrealm.com`
   - Enter API key

## Verification

### Test Prowlarr

1. **Check Indexers**:
   - Go to **Indexers** tab
   - Verify indexers are connected and working
   - Try a test search

### Test SABnzbd

1. **Test Download**:

   - Go to **Wrench** icon → **Test Download**
   - Or manually add a NZB file to test
   - Verify download completes and extracts correctly

2. **Check Folders**:
   ```bash
   # On Docker Swarm node
   ls -la /mnt/nas/media_streaming/downloads/usenet/
   ls -la /mnt/nas/media_streaming/downloads/completed/
   ```

### Test Integration

1. **Prowlarr → SABnzbd**:
   - In Prowlarr, search for something
   - Click download
   - Verify it appears in SABnzbd queue

## Troubleshooting

### Services Won't Start

**Check logs:**

```bash
docker service logs -f prowlarr_prowlarr
docker service logs -f sabnzbd_sabnzbd
```

**Common issues:**

- **NFS mount not available**: Verify mounts are configured
- **Permission errors**: Check folder ownership (should be 1000:1000)
- **Network issues**: Verify `mgmt-network` exists: `docker network ls | grep mgmt`

### Can't Access Web UI

- **Check Traefik**: Verify Traefik is running and routing correctly
- **Check DNS**: Verify DNS records are configured in UniFi
- **Check Firewall**: Verify admin VLAN access is allowed

### Downloads Not Working

- **Check SABnzbd logs**: Look for connection errors
- **Verify Usenet credentials**: Test server connection in SABnzbd
- **Check folder permissions**: Ensure SABnzbd can write to download folders

## Next Steps

Once Phase 1 is working:

1. **Phase 2**: Deploy Sonarr and Radarr
2. **Phase 3**: Deploy Bazarr, Overseerr, Tautulli
3. **Phase 4**: Deploy Tdarr VM

See `specs-homelab/stacks/streaming-stack-deployment-order.md` for complete deployment order.

## Related Documentation

- **Deployment Order**: `specs-homelab/stacks/streaming-stack-deployment-order.md`
- **Access Control**: `specs-homelab/stacks/streaming-stack-access-control.md`
- **Storage Layout**: `specs-homelab/storage/nas-share-layout.md`
