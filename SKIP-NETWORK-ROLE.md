# Skip Network Role - Manual Configuration

## Problem

The network role keeps breaking connectivity. As a workaround, you can skip it and configure network manually.

## Option 1: Skip Network Role in Ansible

Run the playbook without the network role:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml \
  --limit swarm-pi5-01 \
  --ask-become-pass \
  --skip-tags network
```

This will:

- ✅ Install Docker
- ✅ Set up storage (NFS)
- ✅ Configure keepalived
- ✅ Set up Docker Swarm
- ❌ Skip network/VLAN configuration

## Option 2: Configure Network Manually

After skipping the network role, configure VLANs manually on the node:

```bash
# SSH to the node
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13

# Create VLAN interfaces
sudo modprobe 8021q
for vlan in 5 10 15 20 30 40 101 200; do
  sudo ip link add link eth0 name eth0.$vlan type vlan id $vlan 2>/dev/null || true
done

# Configure VLAN IPs (only node IPs, not VIPs)
sudo ip addr add 172.16.5.13/24 dev eth0.5
sudo ip addr add 172.16.10.13/24 dev eth0.10
# VLAN 15 already has IP from base config
sudo ip addr add 172.16.20.13/24 dev eth0.20
sudo ip addr add 172.16.30.13/24 dev eth0.30
sudo ip addr add 172.16.40.13/24 dev eth0.40
sudo ip addr add 172.16.101.13/24 dev eth0.101
sudo ip addr add 172.16.200.13/24 dev eth0.200

# Bring interfaces up
for vlan in 5 10 15 20 30 40 101 200; do
  sudo ip link set eth0.$vlan up
done

# Verify
ip addr show | grep -E "eth0\.(5|10|15|20|30|40|101|200)" | grep "inet "
```

## Option 3: Fix Network Role Issues

The network role needs to:

1. Ensure base interface has static IP BEFORE configuring VLANs
2. Apply netplan changes more carefully
3. Better error handling

This is being worked on, but for now, manual configuration or skipping the role is safer.
