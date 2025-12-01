# Traefik VLAN 5 Kernel Configuration Fix

## Issue

Packets from desktop to `172.16.5.13:80` are not reaching the `eth0.5` interface, even though:
- ✅ Ping works (ICMP packets reach the interface)
- ✅ Node has IP `172.16.5.13` configured on `eth0.5`
- ✅ docker-proxy listening on `0.0.0.0:80`

## Root Cause

The Linux kernel may be:
1. **Rejecting local packets**: `accept_local` might be disabled
2. **Reverse path filtering**: `rp_filter` might be dropping packets due to asymmetric routing
3. **Routing issue**: Kernel might not be delivering packets to the listening socket on VLAN interface

## Fixes Applied

### 1. Enable Accept Local
```bash
sudo sysctl -w net.ipv4.conf.eth0.5.accept_local=1
sudo sysctl -w net.ipv4.conf.all.accept_local=1
```

### 2. Disable Reverse Path Filtering
```bash
sudo sysctl -w net.ipv4.conf.eth0.5.rp_filter=0
sudo sysctl -w net.ipv4.conf.all.rp_filter=0
```

### 3. Enable Non-Local Bind
```bash
sudo sysctl -w net.ipv4.ip_nonlocal_bind=1
```

## Making Changes Persistent

Add to `/etc/sysctl.conf` or `/etc/sysctl.d/99-traefik-vlan5.conf`:

```
net.ipv4.conf.eth0.5.accept_local=1
net.ipv4.conf.all.accept_local=1
net.ipv4.conf.eth0.5.rp_filter=0
net.ipv4.conf.all.rp_filter=0
net.ipv4.ip_nonlocal_bind=1
```

Or add to Ansible playbook for network configuration.

## Testing

From your desktop on VLAN 5:

```bash
curl http://172.16.5.13/
curl -k https://172.16.5.13/dashboard/
```

## Current Status

- ✅ Kernel sysctls updated
- ⚠️ Changes are temporary (need to make persistent)
- ⏳ Testing from desktop

