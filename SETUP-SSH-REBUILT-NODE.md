# Set Up SSH Access on Rebuilt Node

## Option 1: Add SSH Key (Recommended)

**On the rebuilt node (via console), run:**

```bash
# Create .ssh directory
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Add your public key
nano ~/.ssh/authorized_keys
```

**Paste this public key into the file:**

```
<YOUR_PUBLIC_KEY_WILL_BE_SHOWN_BELOW>
```

**Save (Ctrl+X, Y, Enter), then:**

```bash
chmod 600 ~/.ssh/authorized_keys
```

**Test from your Mac:**

```bash
ssh -i ~/.ssh/vm-access-key packer@172.16.15.13
```

## Option 2: Temporarily Enable Password Auth

**On the node (via console):**

```bash
# Enable password authentication
sudo sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

**Then run Ansible with password:**

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-pass --ask-become-pass
```

**After Ansible completes, disable password auth again:**

```bash
# On the node
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

## After SSH Works

Once SSH is working, run the Ansible playbook:

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-become-pass
```

The playbook will now:

- ✅ Find and disable DHCP on the base interface (whatever file it's in)
- ✅ Configure all VLANs correctly
- ✅ Ensure only VLAN 15 has a default route
- ✅ Set up NFS mounts
- ✅ Configure keepalived for VIPs
