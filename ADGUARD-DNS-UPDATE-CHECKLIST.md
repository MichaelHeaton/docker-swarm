# AdGuard DNS Update Checklist

## Current Status

✅ **AdGuard is working!**

- DNS resolving on VLAN 5 (172.16.5.2) ✅
- DNS resolving on VLAN 15 (172.16.15.2) ✅
- DNS on VLAN 101 (172.16.101.2) - may need testing

## DNS Updates Required

### 1. Update DHCP DNS Settings (UniFi Controller)

Update the primary DNS server for each VLAN's DHCP configuration:

**VLAN 5 (Family):**

- **Primary DNS**: `172.16.5.2` (AdGuard - dedicated DNS IP)
- **Secondary DNS**: `172.16.15.1` (UniFi gateway) or `1.1.1.1` (Cloudflare)

**VLAN 101 (Guest):**

- **Primary DNS**: `172.16.101.2` (AdGuard - dedicated DNS IP)
- **Secondary DNS**: `172.16.15.1` (UniFi gateway) or `1.1.1.1` (Cloudflare)

**VLAN 15 (Management):**

- **Primary DNS**: `172.16.15.2` (AdGuard - dedicated DNS IP)
- **Secondary DNS**: `172.16.15.1` (UniFi gateway) or `1.1.1.1` (Cloudflare)

**How to Update:**

1. Open UniFi Controller
2. Go to **Settings** → **Networks**
3. Edit each VLAN (5, 101, 15)
4. Under **DHCP Service**, update **DHCP Name Server**:
   - Primary: `172.16.x.2` (where x is the VLAN ID)
   - Secondary: `172.16.15.1` or `1.1.1.1`
5. Save changes

**Note**: Devices will need to renew their DHCP lease to get the new DNS settings. They can:

- Disconnect and reconnect to WiFi
- Release and renew DHCP lease manually
- Or wait for lease expiration

### 2. Update DNS Records (UniFi Controller)

Update A records to point to AdGuard's dedicated IPs:

**Service DNS Records:**

- `blocker.specterrealm.com` → `172.16.5.2` (VLAN 5 - for end users)
- `adguard-mgmt.specterrealm.com` → `172.16.15.2` (VLAN 15 - for management)

**How to Update:**

1. Open UniFi Controller
2. Go to **Settings** → **DHCP** → **DNS** (or **Networks** → **DHCP** → **DNS Records**)
3. Find or create A records:
   - `blocker.specterrealm.com` → `172.16.5.2`
   - `adguard-mgmt.specterrealm.com` → `172.16.15.2`
4. Save changes

### 3. Verify DNS Resolution

After updating DHCP and DNS records, verify from devices on each VLAN:

**From VLAN 5 Device:**

```bash
# Check DHCP-assigned DNS
cat /etc/resolv.conf
# Should show: nameserver 172.16.5.2

# Test DNS resolution
nslookup google.com
# Should use AdGuard automatically

# Test service DNS
nslookup blocker.specterrealm.com
# Should resolve to 172.16.5.2
```

**From VLAN 101 Device:**

```bash
# Check DHCP-assigned DNS
cat /etc/resolv.conf
# Should show: nameserver 172.16.101.2

# Test DNS resolution
nslookup google.com
# Should use AdGuard automatically
```

**From VLAN 15 Device:**

```bash
# Check DHCP-assigned DNS
cat /etc/resolv.conf
# Should show: nameserver 172.16.15.2

# Test DNS resolution
nslookup google.com
# Should use AdGuard automatically

# Test service DNS
nslookup adguard-mgmt.specterrealm.com
# Should resolve to 172.16.15.2
```

## Testing Checklist

- [ ] DHCP DNS updated for VLAN 5
- [ ] DHCP DNS updated for VLAN 101
- [ ] DHCP DNS updated for VLAN 15
- [ ] DNS A records updated (`blocker.specterrealm.com`, `adguard-mgmt.specterrealm.com`)
- [ ] Tested DNS resolution from VLAN 5 device
- [ ] Tested DNS resolution from VLAN 101 device
- [ ] Tested DNS resolution from VLAN 15 device
- [ ] Verified AdGuard statistics show queries from all VLANs
- [ ] Tested ad-blocking (e.g., `nslookup doubleclick.net`)

## IP Aliases Are Managed by Ansible

The AdGuard IP aliases (`.2` IPs on VLANs 5, 101, and 15) are **automatically configured by Ansible** in the Netplan configuration. The network role will:

1. **Detect** if a node runs AdGuard (`runs_adguard: true` in inventory)
2. **Add** the AdGuard IP to the Netplan config for VLANs that have `adguard_ip` defined
3. **Apply** the configuration automatically

### Ansible Configuration

The AdGuard IPs are defined in `ansible/inventory/swarm-pi5.yml`:

```yaml
swarm_vlans:
  - id: 5
    name: family
    subnet: 172.16.5.0/24
    adguard_ip: 172.16.5.2/32
  - id: 101
    name: guest
    subnet: 172.16.101.0/24
    adguard_ip: 172.16.101.2/32
  - id: 15
    name: mgmt
    subnet: 172.16.15.0/24
    adguard_ip: 172.16.15.2/32
```

And `swarm-pi5-01` has:

```yaml
runs_adguard: true
```

### Apply Configuration

To apply the Ansible configuration:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags network
```

Or run the full playbook:

```bash
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml
```

The Netplan files will be automatically generated with both the node IP and AdGuard IP (if applicable).

## Summary

**What's Working:**

- ✅ AdGuard container running with host networking
- ✅ IP aliases configured (172.16.5.2, 172.16.101.2, 172.16.15.2)
- ✅ DNS resolving on VLAN 5 and VLAN 15
- ✅ AdGuard detecting all interfaces

**What Needs Updating:**

- ⏳ DHCP DNS settings in UniFi Controller (point to .2 IPs)
- ⏳ DNS A records in UniFi Controller (update service names)
- ⏳ Apply Ansible configuration to make IP aliases persistent
- ⏳ Test DNS from VLAN 101 device

**Next Steps:**

1. Update DHCP DNS settings in UniFi Controller
2. Update DNS A records in UniFi Controller
3. Test DNS resolution from devices on all VLANs
4. Make IP aliases persistent
5. Verify AdGuard statistics show queries from all VLANs
