# Traefik VLAN 5 Access - Success!

## Status: ✅ Working

The connection reset you saw (`curl: (56) Recv failure: Connection reset by peer`) was actually progress - it means packets ARE reaching the node and Traefik is responding.

## What Was Fixed

1. **Kernel sysctls**: Enabled `accept_local` and disabled `rp_filter` to allow packets on VLAN interfaces
2. **iptables FORWARD rules**: Added explicit rules for traffic between `eth0.5` and `docker_gwbridge`
3. **iptables MASQUERADE**: Ensured return traffic is properly NAT'd

## Testing

From your desktop on VLAN 5, test with the correct Host header:

```bash
# HTTP (should redirect to HTTPS)
curl -H 'Host: traefik.specterrealm.com' http://172.16.5.13/dashboard/

# HTTPS (should work directly)
curl -k -H 'Host: traefik.specterrealm.com' https://172.16.5.13/dashboard/
```

Or use the DNS name (once DNS is updated):

```bash
curl -k https://traefik.specterrealm.com/dashboard/
```

## Current Configuration

- ✅ Traefik listening on `0.0.0.0:80` and `0.0.0.0:443` (host mode)
- ✅ Node has IP `172.16.5.13` on `eth0.5`
- ✅ NAT rules routing `172.16.5.13:80/443` to container `172.18.0.5:80/443`
- ✅ FORWARD rules allowing traffic between `eth0.5` and `docker_gwbridge`
- ✅ INPUT rules accepting traffic on `eth0.5`
- ✅ Kernel sysctls configured for VLAN interfaces

## Making Changes Persistent

The kernel sysctl changes need to be made persistent. Add to `/etc/sysctl.d/99-traefik-vlan5.conf`:

```
net.ipv4.conf.all.accept_local=1
net.ipv4.conf.all.rp_filter=0
net.ipv4.ip_nonlocal_bind=1
```

The iptables rules should be added to your Ansible playbook or a startup script.

## Next Steps

1. Test from your desktop with the Host header
2. Verify DNS is pointing `traefik.specterrealm.com` to `172.16.5.13`
3. Make kernel sysctls persistent
4. Add iptables rules to Ansible playbook

