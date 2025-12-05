# Setting Up SSH Access for Ansible

## Problem

Ansible can't connect to the rebuilt node because SSH password authentication is likely disabled (security hardening).

## Solution Options

### Option 1: Set Up SSH Keys (Recommended)

**On your local machine:**

```bash
# Generate SSH key if you don't have one
ssh-keygen -t ed25519 -f ~/.ssh/swarm-pi5

# Copy key to node (you'll need console access or password auth temporarily enabled)
ssh-copy-id -i ~/.ssh/swarm-pi5.pub packer@172.16.15.13
```

**Or manually copy the key:**

```bash
# Display your public key
cat ~/.ssh/swarm-pi5.pub

# Then on the node (via console), run:
mkdir -p ~/.ssh
chmod 700 ~/.ssh
echo "YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

**Update Ansible to use the key:**

Add to `ansible/inventory/swarm-pi5.yml`:

```yaml
swarm-pi5-01:
  ansible_ssh_private_key_file: ~/.ssh/swarm-pi5
```

### Option 2: Temporarily Enable Password Auth (Quick Fix)

**On the node (via console):**

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Change:
PasswordAuthentication yes

# Restart SSH
sudo systemctl restart sshd
```

**Then run Ansible:**

```bash
cd ansible
ansible-playbook -i inventory/swarm-pi5.yml playbooks/swarm-setup.yml --limit swarm-pi5-01 --ask-pass
```

**After Ansible runs, disable password auth again:**

```bash
# On node
sudo sed -i 's/PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd
```

### Option 3: Use Ansible Vault for Password

**Create vault file:**

```bash
ansible-vault create ansible/vault/swarm-passwords.yml
```

**Add:**

```yaml
swarm_ssh_password: packer
```

**Update inventory to use vault:**

```yaml
ansible_ssh_pass: "{{ vault_swarm_ssh_password }}"
```

## Quick Test

Try connecting directly first:

```bash
ssh packer@172.16.15.13
```

If that works, Ansible should work too. If not, use one of the options above.
