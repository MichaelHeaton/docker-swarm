# Traefik Port 8080 Ingress Mode Fix

## Issue

Port 8080 in `host` mode was not accessible from desktop on VLAN 5, even though:
- ✅ Port was listening on `0.0.0.0:8080` (docker-proxy)
- ✅ Worked from node itself
- ✅ All iptables rules were in place

## Root Cause

Docker's `host` mode port binding uses `docker-proxy` which may not properly handle traffic from VLAN interfaces. The proxy listens on all interfaces, but the connection handling for VLAN interfaces may not work correctly with Docker Swarm's networking.

## Solution

Changed port 8080 from `host` mode to `ingress` mode. This uses Docker Swarm's ingress network, which properly handles routing across all interfaces and VLANs.

### Change Made

In `stacks/traefik.yml`:
```yaml
# Before (host mode)
- target: 8080
  published: 8080
  protocol: tcp
  mode: host

# After (ingress mode)
- target: 8080
  published: 8080
  protocol: tcp
  mode: ingress
```

## How Ingress Mode Works

- Uses Docker Swarm's ingress network (overlay network)
- Traffic is routed through Swarm's load balancer
- Works across all network interfaces and VLANs
- No need for complex iptables rules for VLAN interfaces

## Testing

From your desktop on VLAN 5:

```bash
curl http://172.16.5.13:8080/dashboard/
```

This should now work because:
1. Ingress mode uses Swarm's overlay network
2. Traffic is routed through Swarm's ingress load balancer
3. Works on any interface the Swarm node has access to

## Trade-offs

### Advantages
- ✅ Works with VLAN interfaces automatically
- ✅ No complex iptables rules needed
- ✅ Uses Swarm's built-in load balancing
- ✅ More consistent with other Swarm services

### Disadvantages
- ⚠️ Slightly more overhead (goes through overlay network)
- ⚠️ Port is accessible on all Swarm nodes (not just the one running Traefik)

## Current Status

- ✅ Port 8080 changed to ingress mode
- ✅ Service redeployed
- ⏳ Testing from desktop

## Next Steps

1. **Test from desktop**: Try `curl http://172.16.5.13:8080/dashboard/`
2. **If working**: Remove temporary iptables rules (they're no longer needed)
3. **If not working**: Check Swarm ingress network configuration

