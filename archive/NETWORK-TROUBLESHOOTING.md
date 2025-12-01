# Network Troubleshooting Guide

## Issue: No Network Connectivity After Static IP Configuration

### Symptoms

- Static IP configured correctly (172.16.15.14/24)
- Gateway route configured (172.16.15.1)
- No connectivity to gateway or internet
- ARP entry for gateway is STALE
- No ARP requests being sent from device

### Diagnosis Steps

1. **Check ARP Table**

   ```bash
   sudo ip neigh show
   ```

   - Gateway should show as REACHABLE, not STALE

2. **Test ARP Resolution**

   ```bash
   sudo arping -c 3 172.16.15.1
   ```

   - Should get ARP replies from gateway

3. **Check Gateway from Another Device**

   ```bash
   # From another device on same VLAN
   ping 172.16.15.1
   ping 172.16.15.14  # The Pi5 node
   ```

4. **Check Switch/VLAN Configuration**

   - Verify Pi5 is on correct VLAN (15 - Mgmt-Admin)
   - Verify switch port is configured for VLAN 15
   - Check for port security or MAC filtering

5. **Check Gateway Firewall Rules**

   - Verify UniFi firewall allows traffic from 172.16.15.14
   - Check if there are any IP-based restrictions

6. **Verify Gateway Routing**
   - Gateway should have route back to 172.16.15.0/24
   - Check gateway ARP table for Pi5 MAC address

### Common Fixes

1. **Refresh ARP Entry**

   ```bash
   sudo ip neigh flush dev eth0
   sudo ip neigh add 172.16.15.1 lladdr 74:ac:b9:e5:e9:f0 dev eth0
   ping 172.16.15.1
   ```

2. **Check UniFi Controller**

   - Verify device is on correct VLAN
   - Check firewall rules
   - Verify static IP reservation (if using DHCP reservation)

3. **Temporary Workaround: Use DHCP**
   - If static IP isn't working, temporarily use DHCP to get connectivity
   - Then troubleshoot why static IP isn't working

### Network Configuration Verification

The Ansible configuration is correct:

- Static IP: 172.16.15.14/24 ✅
- Gateway: 172.16.15.1 ✅
- DNS: 172.16.15.1, 1.1.1.1 ✅
- Routes: Default via 172.16.15.1 ✅

The issue is network infrastructure, not Ansible configuration.
