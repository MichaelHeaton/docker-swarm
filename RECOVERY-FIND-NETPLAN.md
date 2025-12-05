# Recovery: Find and Fix Netplan Config

## Step 1: Find the Netplan File

**On the node (via console), run:**

```bash
# List all netplan files
ls -la /etc/netplan/

# Find which file configures eth0
grep -l "eth0:" /etc/netplan/*.yaml /etc/netplan/*.yml 2>/dev/null
```

**This will show you the actual filename** (might be `50-cloud-init.yaml`, `01-netcfg.yaml`, or something else).

## Step 2: Check Current Config

**Replace `FILENAME` with the actual filename from Step 1:**

```bash
sudo cat /etc/netplan/FILENAME
```

**Look for:**

- `dhcp4: true` or `dhcp4: yes` - This needs to be `false`
- `routes:` section - This should be removed or commented out

## Step 3: Edit the File

```bash
sudo nano /etc/netplan/FILENAME
```

**Change it to:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      dhcp6: false
      addresses:
        - 172.16.15.13/24 # Your node IP
      nameservers:
        addresses:
          - 172.16.15.1
          - 1.1.1.1
```

**IMPORTANT:** Do NOT include a `routes:` section here. The default route should only be on `eth0.15`.

**Save:** Ctrl+X, Y, Enter

## Step 4: Remove DHCP Routes

```bash
# Remove any default routes on eth0 (not eth0.15)
sudo ip route del default via 172.16.15.1 dev eth0 2>/dev/null || true

# Check current routes
ip route show default
```

## Step 5: Apply Netplan

```bash
sudo netplan apply
```

**Wait 10 seconds, then verify:**

```bash
# Should show only ONE default route (on eth0.15)
ip route show default

# Test connectivity
ping -c 3 172.16.15.1
```

## If Still Broken

**Check for multiple default routes:**

```bash
ip route show default
```

**Remove all except eth0.15:**

```bash
# List all default routes
ip route show default

# Remove each one that's NOT on eth0.15
sudo ip route del default via <GATEWAY> dev <INTERFACE>
```

**Then verify:**

```bash
ip route show default
# Should show only: default via 172.16.15.1 dev eth0.15
```
