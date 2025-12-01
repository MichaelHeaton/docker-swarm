# Traefik VLAN 5 Access Diagnosis

## Current Situation

- ✅ Traefik works on `172.16.15.13` (VLAN 15)
- ❌ Traefik does NOT work on `172.16.5.13` (VLAN 5)
- ✅ Ping works to `172.16.5.13` (basic connectivity OK)
- ✅ Node has both IPs configured correctly
- ✅ docker-proxy listening on `0.0.0.0:80` and `0.0.0.0:443`
- ❌ tcpdump shows 0 packets on `eth0.5` when testing from desktop

## Key Finding

**Packets from desktop are NOT reaching the `eth0.5` interface.** This means the issue is happening before packets reach the node's network stack.

## Possible Causes

1. **Kernel routing**: Packets to `172.16.5.13` might be routed incorrectly
2. **Reverse path filtering**: Kernel might be dropping packets due to asymmetric routing
3. **Interface binding**: docker-proxy might not be receiving packets on VLAN 5 interface
4. **Packet filtering**: Something might be dropping TCP packets before they reach the interface

## Fixes Applied

1. ✅ NAT rules for routing VLAN 5 traffic to container
2. ✅ Forward rules for allowing traffic
3. ✅ INPUT rules for accepting traffic
4. ✅ UFW rules for ports 80 and 443
5. ✅ UFW before-input rules
6. ✅ Enabled `net.ipv4.ip_nonlocal_bind`
7. ✅ Moved NAT rules to top of PREROUTING chain
8. ✅ Moved INPUT rules to top of INPUT chain

## Next Steps

Since packets aren't reaching the interface, we need to check:

1. **Desktop network configuration**: Is the desktop actually sending packets to `172.16.5.13`?
2. **Network routing**: Are packets being routed correctly from desktop to node?
3. **Kernel routing table**: Is the kernel routing packets to `172.16.5.13` correctly?

## Testing from Desktop

Please run these commands from your desktop and share the output:

```bash
# Check routing to 172.16.5.13
ip route get 172.16.5.13

# Check if you can reach the interface
ping -c 3 172.16.5.13

# Try telnet to see connection behavior
telnet 172.16.5.13 80

# Check your desktop's network interface
ip addr show | grep 172.16.5
```

This will help us understand if the issue is on the desktop side or the node side.

