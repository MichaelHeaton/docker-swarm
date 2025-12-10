# Phase 1 Deployment Complete! ✅

## Status

**Prowlarr**: ✅ Running (1/1 replicas) - `lscr.io/linuxserver/prowlarr:latest`
**SABnzbd**: ✅ Running (1/1 replicas) - `lscr.io/linuxserver/sabnzbd:latest`

## Access URLs

- **Prowlarr**: `https://prowlarr.specterrealm.com` (Admin VLANs only)
- **SABnzbd**: `https://sabnzbd.specterrealm.com` (Admin VLANs only)

## Next Steps: Configuration

### 1. Configure Prowlarr

1. **Access Prowlarr**: `https://prowlarr.specterrealm.com`
2. **Initial Setup**:
   - Complete the setup wizard
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

### 2. Configure SABnzbd

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

### 3. Test Integration

1. **Test Prowlarr**:

   - Go to **Indexers** tab
   - Verify indexers are connected and working
   - Try a test search

2. **Test SABnzbd**:

   - Go to **Wrench** icon → **Test Download**
   - Or manually add a NZB file to test
   - Verify download completes and extracts correctly

3. **Test Prowlarr → SABnzbd**:
   - In Prowlarr, search for something
   - Click download
   - Verify it appears in SABnzbd queue

## Verification Commands

```bash
# Check service status
docker service ls | grep -E "prowlarr|sabnzbd"

# View logs
docker service logs -f prowlarr_prowlarr
docker service logs -f sabnzbd_sabnzbd

# Check folders
ls -la /mnt/nas/dockers/prowlarr/config
ls -la /mnt/nas/dockers/sabnzbd/config
ls -la /mnt/nas/media_streaming/downloads/
```

## What Changed

- **Images**: Switched from `ghcr.io/hotio/*` to `lscr.io/linuxserver/*` for better ARM64 support
- **All streaming stack services updated**: Sonarr, Radarr, Bazarr, Overseerr, Tautulli also use LinuxServer.io images now

## Ready for Phase 2

Once Prowlarr and SABnzbd are configured and tested, you're ready to deploy:

- **Sonarr** (TV shows)
- **Radarr** (Movies)

See `streaming-stack-deployment-order.md` for Phase 2 deployment steps.
