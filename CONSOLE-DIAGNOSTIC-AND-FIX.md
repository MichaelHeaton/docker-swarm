# Console Diagnostic and Fix Guide

## Step 1: Check Current Routing State

```
ip route show
```

**What to look for:**

- Should see only ONE `default via 172.16.15.1` line
- If you see multiple default routes, that's the problem

## Step 2: Check Interface Status

```
ip addr show
```

**What to look for:**

- `eth0.15` should have IP `172.16.15.X/24` (where X is 13, 15, or 16)
- If `eth0.15` has no IP, that's a problem

## Step 3: Check Netplan Files

```
sudo cat /etc/netplan/50-vlan-15-mgmt.yaml
```

**What to look for:**

- Should have `routes:` section with `via: 172.16.15.1`
- If missing, we need to add it back

## Step 4: Check if Primary Interface Has IP

```
ip addr show eth0
```

**What to look for:**

- Should have IP `172.16.15.X/24`
- If no IP, check the primary interface config

## Step 5: Check Primary Interface Config

```
sudo cat /etc/netplan/00-installer-config.yaml
```

**What to look for:**

- Should have an IP address configured
- If routes were removed, that's OK - but IP must be there

## Step 6: Manual Fix - Restore VLAN 15 Routes (if missing)

If VLAN 15 doesn't have routes, add them back:

```
sudo nano /etc/netplan/50-vlan-15-mgmt.yaml
```

**Make sure it has:**

```yaml
routes:
  - to: 0.0.0.0/0
    via: 172.16.15.1
```

Save and exit (Ctrl+X, Y, Enter)

## Step 7: Ensure Primary Interface Has IP

```
sudo nano /etc/netplan/00-installer-config.yaml
```

**Should look like:**

```yaml
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: false
      addresses:
        - 172.16.15.X/24 # Your node IP (13, 15, or 16)
      nameservers:
        addresses:
          - 172.16.15.1
          - 1.1.1.1
```

**DO NOT add routes section here** - VLAN 15 handles routing

## Step 8: Apply and Test

```
sudo netplan apply
```

Wait 10 seconds, then:

```
ip route show | grep default
```

Should show ONE default route via 172.16.15.1

```
ping -c 3 172.16.15.1
```

Should get replies

## Emergency: If Nothing Works

If you can't get connectivity back, you may need to:

1. Check if you can access via another interface
2. Temporarily enable DHCP to get an IP
3. Or restore from backup

Let me know what you see in Steps 1-5 and I'll help you fix it.

