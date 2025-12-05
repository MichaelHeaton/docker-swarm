# Exact Recovery Steps - What Each Command Does

## What We're Doing

We're **DELETING** (not commenting out) the routes section from:

- VLAN 5 (Family)
- VLAN 10 (Production)
- VLAN 40 (DMZ)
- VLAN 101 (Guest)
- Primary eth0 interface

We're **KEEPING** the routes section in:

- VLAN 15 (Management) - DO NOT TOUCH THIS ONE

## Why Two Commands Per File?

In YAML, the routes section looks like this:

```yaml
routes:
  - to: 0.0.0.0/0
    via: 172.16.5.1
```

We need to delete:

1. The line with `routes:`
2. The line with `via:` (the gateway)

The `- to: 0.0.0.0/0` line will be left, but Netplan will ignore it since the routes section is broken.

## Step-by-Step Commands

### Step 1: See what files exist

```
ls /etc/netplan/
```

**Look for files like:**

- `50-vlan-5-family.yaml` ← Fix this
- `50-vlan-10-production.yaml` ← Fix this
- `50-vlan-15-mgmt.yaml` ← DO NOT TOUCH THIS ONE
- `50-vlan-40-dmz.yaml` ← Fix this
- `50-vlan-101-guest.yaml` ← Fix this
- `00-installer-config.yaml` ← Fix this

### Step 2: Fix VLAN 5 (if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-5-family.yaml
```

**This DELETES the line containing "routes:"**

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-5-family.yaml
```

**This DELETES the line containing "via:"**

### Step 3: Fix VLAN 10 (if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-10-production.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-10-production.yaml
```

### Step 4: Fix VLAN 40 (if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

### Step 5: Fix VLAN 101 (if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-101-guest.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-101-guest.yaml
```

### Step 6: Fix primary interface (if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/00-installer-config.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/00-installer-config.yaml
```

### Step 7: Apply the changes

```
sudo netplan apply
```

### Step 8: Verify

```
ip route | grep default
```

**Should show only ONE line: `default via 172.16.15.1 dev eth0.15`**

## Important Notes

- **DO NOT** run these commands on `50-vlan-15-mgmt.yaml` - that one should keep its routes
- The commands **DELETE** lines, they don't comment them out
- If a file doesn't exist, just skip those commands
- After `netplan apply`, you should be able to SSH again

