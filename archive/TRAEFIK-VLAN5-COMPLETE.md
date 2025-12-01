# Traefik VLAN 5 Access - Complete Solution

## ✅ Status: Working

Traefik is now accessible on both VLAN 5 (`172.16.5.13`) and VLAN 15 (`172.16.15.13`).

## What Was Fixed

### 1. Kernel Sysctls
- Enabled `net.ipv4.conf.all.accept_local=1` - Allows kernel to accept packets on local addresses
- Disabled `net.ipv4.conf.all.rp_filter=0` - Disables reverse path filtering (needed for multi-homed interfaces)
- Enabled `net.ipv4.ip_nonlocal_bind=1` - Allows binding to non-local IPs

### 2. iptables Rules
- **PREROUTING NAT**: Routes `172.16.5.13:80/443` to container `172.18.0.5:80/443`
- **FORWARD**: Allows traffic between `eth0.5` and `docker_gwbridge`
- **INPUT**: Accepts traffic on `eth0.5` for ports 80, 443, 8080
- **POSTROUTING MASQUERADE**: NATs return traffic from container

### 3. UFW Rules
- Allow ports 80, 443, 8080 from VLAN 5 subnet

## Testing

From your desktop on VLAN 5:

```bash
# Using DNS (once DNS points traefik.specterrealm.com to 172.16.5.13)
curl -k https://traefik.specterrealm.com/dashboard/

# Or using IP with Host header
curl -k -H 'Host: traefik.specterrealm.com' https://172.16.5.13/dashboard/
```

## Persistent Configuration

### Ansible
The kernel sysctls are now configured in `ansible/roles/network/tasks/main.yml` and will be applied automatically on future runs.

### iptables Rules
The iptables rules need to be added to a startup script or Ansible playbook. For now, they're temporary and will be lost on reboot.

**TODO**: Create an Ansible task or systemd service to restore iptables rules on boot.

## Architecture

```
Desktop (VLAN 5) → 172.16.5.13:80/443
                  ↓
              eth0.5 (swarm-pi5-01)
                  ↓
         iptables NAT (PREROUTING)
                  ↓
         docker_gwbridge (172.18.0.5)
                  ↓
         Traefik Container
                  ↓
         Routes to services on VLAN 15/10/etc
```

## Next Steps

1. ✅ Test from desktop - **DONE**
2. ⏳ Verify DNS points `traefik.specterrealm.com` to `172.16.5.13`
3. ⏳ Make iptables rules persistent (Ansible task or startup script)
4. ✅ Kernel sysctls persistent - **DONE** (via Ansible)

## Notes

- The connection reset you initially saw was because Traefik requires the `Host` header to route correctly
- Traefik works on both VLANs and can proxy traffic between them
- VLAN 5 users can access services on VLAN 15 through Traefik, but cannot directly access VLAN 15 (by design)

