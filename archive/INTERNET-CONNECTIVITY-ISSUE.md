# Internet Connectivity Issue - swarm-pi5-02

## Status

- **swarm-pi5-02 (172.16.15.14, MAC: 2c:cf:67:42:9d:8b)**: ❌ Cannot reach internet (8.8.8.8)
- **swarm-pi5-03 (172.16.15.15)**: ✅ Can reach internet (8.8.8.8)
- **swarm-pi5-04 (172.16.15.16)**: ✅ Can reach internet
- **Gateway (172.16.15.1)**: ✅ Reachable from swarm-pi5-02

## Diagnosis

### Node Configuration ✅

- Routing: Correct (default via 172.16.15.1)
- Firewall: UFW allows outgoing traffic
- Network interface: UP and configured correctly
- Local network: Working (can ping gateway and other nodes)
- **Tested with both static IP and DHCP** - issue persists

### Gateway/Infrastructure Issue ❌

The issue is **NOT** a firewall rule (other nodes on same VLAN work), but appears to be **device-specific**.

**Evidence:**

1. swarm-pi5-03 and swarm-pi5-04 can reach internet from the same VLAN
2. swarm-pi5-02 cannot reach internet even with DHCP
3. Gateway is reachable from swarm-pi5-02
4. tcpdump shows NO packets when pinging 8.8.8.8 (packets not leaving interface)
5. Route lookup fails when specifying source interface: `ip route get 8.8.8.8 from 172.16.15.14 iif eth0` → "No route to host"

## Root Cause (Likely)

**Device-specific restriction in UniFi Controller:**

- MAC address filtering/blocking (2c:cf:67:42:9d:8b)
- Port security on the switch port
- Device-specific firewall rule or traffic rule
- Device group membership issue
- Client isolation or device-specific network policy

## Solution

### Check UniFi Controller:

1. **Device-Specific Rules:**

   - Settings → Firewall & Security → Firewall Rules
   - Look for rules targeting MAC address `2c:cf:67:42:9d:8b` or IP `172.16.15.14`
   - Check Traffic Rules for device-specific restrictions

2. **Device Settings:**

   - Clients → Find device with MAC `2c:cf:67:42:9d:8b`
   - Check if device is in a restricted group or has client isolation enabled
   - Verify device is on correct network (VLAN 15 - Mgmt-Admin)

3. **Switch Port Settings:**

   - Devices → Find switch → Check port where swarm-pi5-02 is connected
   - Verify port security settings
   - Check for MAC address filtering on the port
   - Ensure port is on correct VLAN (15)

4. **Network Policies:**
   - Settings → Networks → VLAN 15 (Mgmt-Admin)
   - Check for client isolation or device-specific policies
   - Verify MAC address isn't blocked

### Quick Fix Options:

1. **Forget and Re-adopt Device:**

   - In UniFi Controller, forget the device
   - Re-adopt it to clear any cached restrictions

2. **Check Device Group:**

   - Move device to a different group temporarily to test
   - Or ensure it's in the correct group with internet access

3. **Port Security:**
   - Check if port has MAC address limit or filtering
   - Temporarily disable port security to test

## Impact

- **Docker Swarm Setup**: Can proceed (doesn't require internet during initial setup)
- **Package Installation**: May fail if packages need to be downloaded
- **SSL Certificates**: Will fail if using Let's Encrypt (needs internet)

## Next Steps

1. Check UniFi Controller for device-specific restrictions (MAC: 2c:cf:67:42:9d:8b)
2. Verify switch port settings
3. Test after removing any restrictions
4. Continue with Docker Swarm setup once resolved
