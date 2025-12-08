# Docker Swarm NFS Shares Summary

## Planned NFS Shares (from Ansible Storage Role)

The Ansible storage role is configured to mount **6 NFS shares**:

- **2 Docker storage shares** - medium IOPS from NAS02, high IOPS from NAS01
- **3 Media shares** from NAS02 (172.16.30.4) - for Plex and related services
- **1 Backup share** from NAS01 (172.16.30.5)

### Docker Storage Shares

| Local Mount Point       | Remote Path               | NAS   | Purpose                                                          | Status                |
| ----------------------- | ------------------------- | ----- | ---------------------------------------------------------------- | --------------------- |
| `/mnt/nas/dockers`      | `/var/nfs/shared/dockers` | NAS02 | Medium IOPS Docker storage - organized by service name           | ⚠️ Needs verification |
| `/mnt/nas/dockers-iops` | `/volume1/dockers-iops`   | NAS01 | High IOPS Docker storage (SSD cache) - organized by service name | ⚠️ Needs verification |

### Media Shares (NAS02) - For Plex and Related Services

| Local Mount Point          | Remote Path (NAS02)               | Purpose                | Status                |
| -------------------------- | --------------------------------- | ---------------------- | --------------------- |
| `/mnt/nas/media_streaming` | `/var/nfs/shared/media_streaming` | Streaming media (Plex) | ⚠️ Needs verification |
| `/mnt/nas/media_family`    | `/var/nfs/shared/media_family`    | Family photos/videos   | ⚠️ Needs verification |
| `/mnt/nas/media_stashapp`  | `/var/nfs/shared/media_stashapp`  | Stash app media        | ⚠️ Needs verification |

### Backup Share (NAS01)

| Local Mount Point  | Remote Path (NAS01) | Purpose         | Status                |
| ------------------ | ------------------- | --------------- | --------------------- |
| `/mnt/nas/backups` | `/volume3/backup`   | General backups | ⚠️ Needs verification |

**Source**: `ansible/roles/storage/tasks/main.yml`

## NAS Configuration

### NAS02 (UniFi UNAS Pro) - Primary Storage

- **IP**: 172.16.30.4 (Storage VLAN)
- **NFS Version**: NFSv3
- **Path Format**: `/var/nfs/shared/{share_name}`

**Shares Used**:

- ✅ `dockers` - Medium IOPS Docker storage (1 TB)
- ✅ `media_streaming` - Streaming media (60 TB)
- ✅ `media_family` - Family photos/videos (5 TB)
- ✅ `media_stashapp` - Stash app media (7 TB)

### NAS01 (Synology) - Backup Storage

- **IP**: 172.16.30.5 (Storage VLAN)
- **NFS Version**: NFSv4
- **Path Format**: `/volume{number}/{share_name}`

**Shares Used**:

- ✅ `dockers-iops` - High IOPS Docker storage (2 TB, Volume 1 with SSD cache)
- ✅ `backup` - General backup storage (Volume 3)

## Configuration Details

### Docker Storage Structure

Both `dockers` (NAS02) and `dockers-iops` (NAS01) use the same folder structure, organized by service name:

```
/dockers/ or /dockers-iops/
├── {service-name}/
│   ├── compose.yaml
│   ├── config/
│   ├── data/
│   └── logs/
└── backups/
```

**Example**: For a service named `adguard`:

- **Medium IOPS**: `/mnt/nas/dockers/adguard/config/`, `/data/`, `/logs/`
- **High IOPS**: `/mnt/nas/dockers-iops/adguard/config/`, `/data/`, `/logs/`

**When to use which**:

- **`dockers-iops`** (NAS01): Databases, observability tools, game servers, or any service requiring high random I/O
- **`dockers`** (NAS02): Regular services that don't need high IOPS

**Note**: Services create their own directories as needed. Choose the appropriate mount point based on performance requirements.

### NFS Protocol Versions

- **NAS02**: Uses NFSv3 (required for UniFi UNAS Pro)
- **NAS01**: Uses NFSv4 (Synology supports both v3 and v4)

## Next Steps

1. **Verify NAS02 NFS Exports**:

   ```bash
   # From swarm-pi5-01
   showmount -e 172.16.30.4
   ```

2. **Verify NAS01 NFS Exports**:

   ```bash
   # From swarm-pi5-01
   showmount -e 172.16.30.5
   ```

3. **Verify Docker shares are accessible**:

   - **Medium IOPS**: `/mnt/nas/dockers` from NAS02
   - **High IOPS**: `/mnt/nas/dockers-iops` from NAS01
   - Services will create their own directories as needed (e.g., `dockers/adguard/`, `dockers-iops/prometheus/`, etc.)

4. **Configure NFS exports on NAS02**:

   - Ensure `dockers`, `media_streaming`, `media_family`, `media_stashapp` shares are exported
   - Export to `172.16.30.0/24` network
   - Set appropriate permissions (read/write)

5. **Configure NFS exports on NAS01**:

   - Ensure `dockers-iops` and `backup` shares are exported
   - Export to `172.16.30.0/24` network
   - Set appropriate permissions (read/write)

## Current Status

From verification script output:

- ✗ `/mnt/nas/docker/configs` is NOT mounted

This suggests either:

1. NFS shares don't exist on NAS02
2. NFS exports are not configured on NAS02
3. Network connectivity issue (unlikely, as other checks passed)
4. NFS version mismatch (NAS02 requires NFSv3)

## Verification Commands

```bash
# Check NFS exports from NAS02
showmount -e 172.16.30.4

# Check NFS exports from NAS01
showmount -e 172.16.30.5

# Check if mount points exist locally
ls -la /mnt/nas/dockers
ls -la /mnt/nas/dockers-iops
ls -la /mnt/nas/media_streaming
ls -la /mnt/nas/media_family
ls -la /mnt/nas/media_stashapp
ls -la /mnt/nas/backups

# Check /etc/fstab entries
grep nfs /etc/fstab

# Try manual mount from NAS02 (if exports exist)
sudo mount -t nfs -o vers=3 172.16.30.4:/var/nfs/shared/dockers /mnt/nas/dockers

# Try manual mount from NAS01 (if exports exist)
sudo mount -t nfs4 172.16.30.5:/volume1/dockers-iops /mnt/nas/dockers-iops
sudo mount -t nfs4 172.16.30.5:/volume3/backup /mnt/nas/backups
```
