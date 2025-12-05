# Testing on swarm-pi5-01 Only

## Safe Testing Approach

Run Ansible **only on swarm-pi5-01** first to verify everything works before touching other nodes.

## Command to Run

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01
```

This will:

- ✅ Configure all VLANs (5, 10, 15, 20, 30, 40, 101, 200)
- ✅ Set up IP addresses on each VLAN
- ✅ Configure AdGuard IPs (172.16.5.2, 172.16.15.2, 172.16.101.2)
- ✅ Set up NFS mounts from NAS01
- ✅ Deploy keepalived with DNS and Traefik VIPs
- ✅ Install Docker
- ✅ Configure Docker Swarm (if first node)

## Verification Checklist

After running, verify on swarm-pi5-01:

### 1. Check All VLAN Interfaces

```bash
ip addr show | grep -E "eth0\.(5|10|15|20|30|40|101|200)" | grep "inet "
```

**Expected:**

- eth0.5: 172.16.5.13/24 + 172.16.5.2/32 (AdGuard VIP)
- eth0.10: 172.16.10.13/24
- eth0.15: 172.16.15.13/24 + 172.16.15.2/32 (AdGuard VIP)
- eth0.20: 172.16.20.13/24
- eth0.30: 172.16.30.13/24 (storage)
- eth0.40: 172.16.40.13/24
- eth0.101: 172.16.101.13/24 + 172.16.101.2/32 (AdGuard VIP)
- eth0.200: 172.16.200.13/24

### 2. Check Routes (Should be ONLY ONE default route)

```bash
ip route show | grep default
```

**Expected:**

- `default via 172.16.15.1 dev eth0.15` (ONLY ONE)

### 3. Check VIPs (DNS .2 and Traefik .3)

```bash
ip addr show | grep -E "172\.16\.(5|15|101|40)\.(2|3)"
```

**Expected:**

- 172.16.5.2 (DNS VIP)
- 172.16.5.3 (Traefik VIP)
- 172.16.15.2 (DNS VIP)
- 172.16.15.3 (Traefik VIP)
- 172.16.101.2 (DNS VIP)
- 172.16.101.3 (Traefik VIP)
- 172.16.40.3 (Traefik VIP)

### 4. Check NFS Mounts

```bash
mount | grep nfs
```

**Expected:**

- 172.16.30.5:/volume1/docker/Configs on /mnt/nas/docker/configs
- 172.16.30.5:/volume1/docker/Volumes on /mnt/nas/docker/volumes
- 172.16.30.5:/volume1/docker/Logs on /mnt/nas/docker/logs
- 172.16.30.5:/volume1/docker/Secrets on /mnt/nas/docker/secrets
- 172.16.30.5:/volume1/docker/Backups on /mnt/nas/docker/backups

### 5. Check Keepalived Status

```bash
systemctl status keepalived
ip addr show | grep "172.16.*.2\|172.16.*.3"
```

### 6. Test Connectivity

```bash
# Test gateway on each VLAN
ping -c 2 172.16.5.1
ping -c 2 172.16.15.1
ping -c 2 172.16.30.5  # NAS storage
```

### 7. Test DNS (if AdGuard is deployed)

```bash
nslookup google.com 172.16.15.2
```

## If Everything Looks Good

Once swarm-pi5-01 is verified working:

1. Document what worked
2. Then run on other nodes:
   ```bash
   ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-02,swarm-pi5-03,swarm-pi5-04
   ```

## If Something Breaks

- **Network issues**: Check routes, VLAN interfaces
- **VIP issues**: Check keepalived logs: `journalctl -u keepalived`
- **NFS issues**: Check connectivity to NAS: `ping 172.16.30.5`

## Safety Notes

- Only swarm-pi5-01 will be affected
- Other nodes remain untouched
- Can rollback by rebuilding node if needed
- All configuration is in Ansible (version controlled)
