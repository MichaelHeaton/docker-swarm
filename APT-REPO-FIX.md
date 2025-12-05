# Apt Repository Fix

## Problem

Ubuntu apt repositories were missing Release files, causing package installation to fail with errors like:

```
E:The repository 'http://ports.ubuntu.com/ubuntu-ports noble Release' no longer has a Release file.
```

## Root Cause

This typically happens when:

1. The system's apt sources.list has outdated or incorrect repository URLs
2. The repositories have been moved or restructured
3. The apt cache is corrupted

## Fix Applied

Added tasks to the storage role that:

1. **Wait for apt lock** - Ensures no other process is using apt
2. **Clean apt cache** - Removes corrupted cache files
3. **Remove broken cache files** - Cleans up partial downloads
4. **Try to update** - Attempts normal apt update first
5. **Fix repositories if needed** - If update fails, replaces sources.list with correct Ubuntu repositories
6. **Clean and update again** - After fixing, cleans cache and updates

## What Changed

### Before

- Storage role tried to install `nfs-common` directly
- Failed immediately if repositories were broken
- No recovery mechanism

### After

- Checks and fixes repositories before installing packages
- Backs up original sources.list
- Replaces with correct Ubuntu repository URLs
- Retries after fixing

## Repository URLs Used

For Ubuntu 24.04 (Noble):

- `http://ports.ubuntu.com/ubuntu-ports/ noble main restricted universe multiverse`
- `http://ports.ubuntu.com/ubuntu-ports/ noble-updates main restricted universe multiverse`
- `http://ports.ubuntu.com/ubuntu-ports/ noble-security main restricted universe multiverse`
- `http://ports.ubuntu.com/ubuntu-ports/ noble-backports main restricted universe multiverse`

These are the standard Ubuntu ARM64 (ports) repositories.

## Testing

Run the playbook again:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml \
  --limit swarm-pi5-01 \
  --ask-become-pass
```

The storage role should now:

1. Detect broken repositories
2. Fix them automatically
3. Install nfs-common successfully
