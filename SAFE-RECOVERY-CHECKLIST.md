# Safe Recovery Checklist - One Command at a Time

## Before Starting

- [ ] You have console access
- [ ] You can see the command prompt
- [ ] You understand: if a file doesn't exist, skip those commands

## Recovery Steps (Type ONE command, press Enter, wait for prompt)

### 1. See what files we have

```
ls /etc/netplan/
```

**Wait for output, then continue**

### 2. Fix VLAN 5 (only if file exists from step 1)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-5-family.yaml
```

**Press Enter, wait for prompt**

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-5-family.yaml
```

**Press Enter, wait for prompt**

### 3. Fix VLAN 10 (only if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-10-production.yaml
```

**Press Enter, wait for prompt**

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-10-production.yaml
```

**Press Enter, wait for prompt**

### 4. Fix VLAN 40 (only if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

**Press Enter, wait for prompt**

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-40-dmz.yaml
```

**Press Enter, wait for prompt**

### 5. Fix VLAN 101 (only if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/50-vlan-101-guest.yaml
```

**Press Enter, wait for prompt**

```
sudo sed -i '/via:/d' /etc/netplan/50-vlan-101-guest.yaml
```

**Press Enter, wait for prompt**

### 6. Fix primary interface (only if file exists)

```
sudo sed -i '/routes:/d' /etc/netplan/00-installer-config.yaml
```

**Press Enter, wait for prompt**

```
sudo sed -i '/via:/d' /etc/netplan/00-installer-config.yaml
```

**Press Enter, wait for prompt**

### 7. Apply the changes

```
sudo netplan apply
```

**Wait for this to complete (may take 5-10 seconds)**

### 8. Verify it worked

```
ip route | grep default
```

**Should show ONE line only**

## If you see errors about files not existing, that's OK - just skip those commands

## After Recovery

Test SSH from another machine:

```
ssh packer@172.16.15.13
```
