# Simple Blind Recovery - Short Commands Only

## IMPORTANT: Type each command, press Enter, wait for prompt before next command

### Step 1: Check what files exist

```
ls /etc/netplan/
```

### Step 2: Fix VLAN 5 (if it exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-5-family.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-5-family.yaml
```

### Step 3: Fix VLAN 10 (if it exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-10-production.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-10-production.yaml
```

### Step 4: Fix VLAN 40 (if it exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

### Step 5: Fix VLAN 101 (if it exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-101-guest.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-101-guest.yaml
```

### Step 6: Fix primary interface (if it exists)

```
sudo sed -i '/routes:/d' /etc/netplan/00-installer-config.yaml
```

```
sudo sed -i '/via:/d' /etc/netplan/00-installer-config.yaml
```

### Step 7: Apply the fix

```
sudo netplan apply
```

### Step 8: Check if it worked

```
ip route | grep default
```

Should show only ONE line with "default via 172.16.15.1"

## If a file doesn't exist, skip those commands - that's OK
