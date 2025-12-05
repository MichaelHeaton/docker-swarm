# DNS Virtual IP (VIP) High Availability Setup

## Problem

DNS is currently hardcoded to `172.16.15.13` (swarm-pi5-01). If that node fails, DNS fails for the entire network.

## Solution: Virtual IP (VIP) with Keepalived

Use **keepalived** to provide floating Virtual IPs that can move between nodes automatically:

- **VIP on VLAN 5**: `172.16.5.2` (floats between nodes running AdGuard)
- **VIP on VLAN 15**: `172.16.15.2` (floats between nodes running AdGuard)
- **VIP on VLAN 101**: `172.16.101.2` (floats between nodes running AdGuard)

### How It Works

1. **Keepalived** runs on all manager nodes
2. **Primary node** (swarm-pi5-01) has highest priority (110) - holds VIPs
3. **Backup nodes** (swarm-pi5-02, swarm-pi5-03) have lower priorities (100, 90)
4. **Health check** monitors DNS service (port 53)
5. **If primary fails**, VIP automatically moves to backup node
6. **DNS records** point to VIPs, not node IPs

## Configuration

### Ansible Inventory

VIP priorities are set in `ansible/inventory/swarm-pi5.yml`:

```yaml
swarm-pi5-01:
  keepalived_priority: 110 # Primary (highest)
  keepalived_state: MASTER
  runs_adguard: true

swarm-pi5-02:
  keepalived_priority: 100 # Backup
  keepalived_state: BACKUP

swarm-pi5-03:
  keepalived_priority: 90 # Backup (lowest)
  keepalived_state: BACKUP
```

### VIP IPs

- **VLAN 5**: `172.16.5.2` (Family DNS)
- **VLAN 15**: `172.16.15.2` (Management DNS)
- **VLAN 101**: `172.16.101.2` (Guest DNS)

These are the same IPs we're already using for AdGuard, but now they're **floating VIPs** instead of static IPs on one node.

## Deployment

### Step 1: Deploy Keepalived

Keepalived is automatically deployed by Ansible:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --tags keepalived
```

### Step 2: Verify VIPs

On primary node (swarm-pi5-01):

```bash
ip addr show eth0.5 | grep 172.16.5.2
ip addr show eth0.15 | grep 172.16.15.2
ip addr show eth0.101 | grep 172.16.101.2
```

Should show VIPs are active.

### Step 3: Test Failover

1. **Stop AdGuard on primary node:**

   ```bash
   docker stop adguard
   ```

2. **Watch VIP move:**

   ```bash
   # On backup node
   ip addr show eth0.15 | grep 172.16.15.2
   ```

3. **VIP should move to backup node** within 5-10 seconds

4. **Restart AdGuard on backup node** (or deploy it there)

### Step 4: Update DNS Records

Update UniFi Controller DNS records to point to VIPs:

- `blocker.specterrealm.com` → `172.16.5.2` (VIP, not node IP)
- `adguard-mgmt.specterrealm.com` → `172.16.15.2` (VIP, not node IP)

### Step 5: Update DHCP DNS Settings

Update UniFi Controller DHCP settings:

- **VLAN 5**: Primary DNS → `172.16.5.2` (VIP)
- **VLAN 101**: Primary DNS → `172.16.101.2` (VIP)
- **VLAN 15**: Primary DNS → `172.16.15.2` (VIP)

## AdGuard Deployment Strategy

### Option 1: Single Instance with VIP (Current)

- AdGuard runs on swarm-pi5-01
- VIP floats to backup if node fails
- **Requires**: AdGuard must be deployed on backup node when failover occurs

### Option 2: Multiple Instances (Recommended for True HA)

- Deploy AdGuard on multiple nodes
- VIP floats to node with running AdGuard
- **Better**: True high availability, no manual intervention

**To implement Option 2:**

1. Deploy AdGuard on swarm-pi5-01, swarm-pi5-02, swarm-pi5-03
2. Each listens on `0.0.0.0:53`
3. VIP floats to node with healthy AdGuard
4. All nodes can serve DNS simultaneously

## Benefits

✅ **High Availability** - DNS survives node failures
✅ **No Hardcoded IPs** - DNS points to VIPs, not node IPs
✅ **Automatic Failover** - VIP moves automatically
✅ **Health Monitoring** - Keepalived checks DNS service health
✅ **Transparent** - Clients don't need to know which node is serving DNS

## Monitoring

### Check Keepalived Status

```bash
systemctl status keepalived
ip addr show | grep "172.16.*.2"
```

### Check VIP Ownership

```bash
# On each node
ip addr show eth0.15 | grep "172.16.15.2"
# Only one node should show the VIP
```

### View Keepalived Logs

```bash
journalctl -u keepalived -f
```

## Troubleshooting

### VIP Not Moving

1. Check keepalived is running: `systemctl status keepalived`
2. Check health check: `nc -z -u localhost 53`
3. Check priorities: `cat /etc/keepalived/keepalived.conf`
4. Check logs: `journalctl -u keepalived`

### Multiple VIPs Active

- This shouldn't happen, but if it does:
- Check network connectivity between nodes
- Verify authentication password matches on all nodes
- Check for network partitions

## Security

- **Authentication**: Keepalived uses password authentication
- **Password**: Should be stored in Ansible Vault (not plaintext)
- **Network**: VIPs only on management/storage VLANs (not exposed externally)

## Next Steps

1. ✅ Keepalived role created
2. ✅ Inventory updated with priorities
3. ⏳ Deploy keepalived on all manager nodes
4. ⏳ Update DNS records to use VIPs
5. ⏳ Test failover scenario
6. ⏳ Consider deploying AdGuard on multiple nodes for true HA
