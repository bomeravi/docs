# SSH Key Generation and Management

Complete guide for generating, managing, and deploying SSH keys on Ubuntu/Linux systems.

---

## Prerequisites

Ensure OpenSSH is installed:
```bash
sudo apt update
sudo apt install openssh-client openssh-server
```

---

## Part 1: SSH Key Generation

### Overview of Key Types

- **RSA**: Traditional, 2048-bit recommended minimum, wider compatibility
- **ED25519**: Modern, faster, more secure, excellent choice for new keys

---

## RSA Key Generation

### Method 1: Generate RSA Key with Default Name

The default location and name is `~/.ssh/id_rsa`:

```bash
ssh-keygen -t rsa -b 4096
```

When prompted, press **Enter** to accept defaults:
```
Generating public/private rsa key pair.
Enter file in which to save the key (/home/ubuntu/.ssh/id_rsa): [press Enter]
Enter passphrase (empty for no passphrase): [enter passphrase or press Enter]
Enter same passphrase again: [repeat passphrase]
```

**Output files:**
- Private key: `~/.ssh/id_rsa` (keep this secret!)
- Public key: `~/.ssh/id_rsa.pub` (safe to share)

### Method 2: Generate RSA Key with Custom Name

For multiple keys or specific purposes:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_work -C "work@company.com"
```

Parameters:
- `-t rsa`: Key type
- `-b 4096`: Key size (bits)
- `-f`: File path and name
- `-C`: Comment (email or identifier)

**Prompt:**
```
Enter passphrase (empty for no passphrase): [enter passphrase]
Enter same passphrase again: [repeat passphrase]
```

**Output files:**
- `~/.ssh/id_rsa_work`
- `~/.ssh/id_rsa_work.pub`

### Custom RSA Examples

```bash
# For GitHub
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_github -C "github_username"

# For GitLab
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_gitlab -C "gitlab_username"

# For server access
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_server -C "server-key"

# For personal use
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa_personal -C "personal-machine"
```

---

## ED25519 Key Generation (Recommended)

ED25519 is faster and equally secure with smaller key sizes. **Recommended for new setups.**

### Method 1: Generate ED25519 Key with Default Name

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
```

Default location: `~/.ssh/id_ed25519`

**Prompt:**
```
Enter file in which to save the key (/home/ubuntu/.ssh/id_ed25519): [press Enter]
Enter passphrase (empty for no passphrase): [enter passphrase]
Enter same passphrase again: [repeat passphrase]
```

**Output files:**
- Private key: `~/.ssh/id_ed25519`
- Public key: `~/.ssh/id_ed25519.pub`

### Method 2: Generate ED25519 Key with Custom Name

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_work -C "work@company.com"
```

### Custom ED25519 Examples

```bash
# For GitHub
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "your_github_email@example.com"

# For GitLab
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_gitlab -C "your_gitlab_email@example.com"

# For production server
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_prod -C "production-server"

# For development
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_dev -C "dev-environment"
```

---

## View Your Keys

### List all SSH keys
```bash
ls -la ~/.ssh/
```

### View public key content
```bash
cat ~/.ssh/id_rsa.pub
# or
cat ~/.ssh/id_ed25519.pub
```

### Check key fingerprint
```bash
ssh-keygen -l -f ~/.ssh/id_rsa.pub
# or
ssh-keygen -l -f ~/.ssh/id_ed25519.pub
```

---

## Part 2: SSH Agent Management

The SSH Agent securely stores your private keys in memory, allowing passwordless authentication.

### Start SSH Agent

```bash
# Automatically start the SSH agent
eval "$(ssh-agent -s)"
```

Expected output:
```
Agent pid 5906
```

### Check if SSH Agent is Running

```bash
echo $SSH_AUTH_SOCK
```

If it returns nothing, the agent is not running.

### Add Default Keys to SSH Agent

```bash
# Add default RSA key
ssh-add ~/.ssh/id_rsa

# Add default ED25519 key
ssh-add ~/.ssh/id_ed25519

# Add both (if both exist)
ssh-add ~/.ssh/id_rsa ~/.ssh/id_ed25519
```

### Add Custom Named Keys to SSH Agent

```bash
ssh-add ~/.ssh/id_rsa_work
ssh-add ~/.ssh/id_ed25519_github
ssh-add ~/.ssh/id_rsa_server
```

**Prompt (if key has passphrase):**
```
Enter passphrase for /home/ubuntu/.ssh/id_rsa_work: [enter passphrase]
```

### List All Added Keys

```bash
ssh-add -l
```

Example output:
```
2048 SHA256:xvXQvF8aQ7y9K3mP2... /home/ubuntu/.ssh/id_rsa (RSA)
256 SHA256:aBc1DeF2gHi3JkL4m... /home/ubuntu/.ssh/id_ed25519 (ED25519)
2048 SHA256:nOpQrStUvWxYzAbC... /home/ubuntu/.ssh/id_rsa_work (RSA)
```

### Add Key with Custom Timeout

```bash
# Key expires from agent after 3600 seconds (1 hour)
ssh-add -t 3600 ~/.ssh/id_rsa
```

### Remove Specific Key from SSH Agent

```bash
ssh-add -d ~/.ssh/id_rsa
```

### Remove All Keys from SSH Agent

```bash
ssh-add -D
```

### Auto-load Keys on Login

Add this to your `~/.bashrc` or `~/.bash_profile`:

```bash
# Start SSH agent and load keys automatically
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null
fi
```

For **Zsh** users, add to `~/.zshrc`:

```bash
# Auto-start SSH agent with key loading
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519 2>/dev/null
    ssh-add ~/.ssh/id_rsa 2>/dev/null
fi
```

---

## Part 3: Deploying Keys to Servers

### Method 1: Using ssh-copy-id (Easiest)

**Prerequisites:** You can SSH to the server with password authentication, or the key is already in SSH agent.

#### Deploy Default Key

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub username@server_ip
```

**Prompt:**
```
The authenticity of host '192.168.1.100 (192.168.1.100)' can't be established.
ECDSA key fingerprint is SHA256:...
Are you sure you want to continue connecting (yes/no)? yes
```

Enter server password when prompted.

#### Deploy Custom Named Key

```bash
ssh-copy-id -i ~/.ssh/id_rsa_server.pub user@10.0.0.5
```

#### Deploy Multiple Keys

```bash
ssh-copy-id -i ~/.ssh/id_ed25519.pub -i ~/.ssh/id_rsa.pub user@server_ip
```

#### Examples with Different Server Ports

```bash
# Server on custom SSH port (2222)
ssh-copy-id -i ~/.ssh/id_ed25519.pub -p 2222 user@server_ip

# IPv6 address
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@[2001:db8::1]
```

---

### Method 2: Manual Deployment

Use this method if `ssh-copy-id` is unavailable or for batch operations.

#### Step 1: Get Your Public Key

```bash
cat ~/.ssh/id_ed25519.pub
```

Output:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKx1... your_email@example.com
```

#### Step 2: Login to Server

```bash
ssh username@server_ip
```

#### Step 3: Ensure SSH Directory Exists

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh
```

#### Step 4: Add Public Key to authorized_keys

```bash
# Option A: If you have the key in clipboard
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKx1... your_email@example.com" >> ~/.ssh/authorized_keys

# Option B: Using a text editor
nano ~/.ssh/authorized_keys
# (paste your public key, then Ctrl+O, Enter, Ctrl+X)

# Option C: Using cat with heredoc
cat >> ~/.ssh/authorized_keys << 'EOF'
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKx1... your_email@example.com
EOF
```

#### Step 5: Set Correct Permissions

```bash
chmod 600 ~/.ssh/authorized_keys
chmod 700 ~/.ssh
```

#### Step 6: Exit and Test

```bash
exit
```

Test the connection:
```bash
ssh username@server_ip
```

#### Step 7: Disable Password Authentication (Optional but Recommended)

On the server, edit SSH config:
```bash
sudo nano /etc/ssh/sshd_config
```

Find and modify:
```
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart ssh
```

---

## Part 4: Adding Public Keys from GitHub and GitLab

### Adding GitHub Public Keys

#### Method 1: Fetch from GitHub

Get your GitHub username and public keys:

```bash
# Fetch your GitHub public keys
curl https://github.com/<YOUR_GITHUB_USERNAME>.keys
```

Example:
```bash
curl https://github.com/bomeravi.keys
```

#### Method 2: Add to Server

```bash
# Fetch and add in one command
curl https://github.com/<YOUR_GITHUB_USERNAME>.keys >> ~/.ssh/authorized_keys

# Example:
curl https://github.com/bomeravi.keys >> ~/.ssh/authorized_keys
```

Then fix permissions on server:
```bash
chmod 600 ~/.ssh/authorized_keys
```

#### Method 3: Manual GitHub Key Addition

1. Go to GitHub profile settings: https://github.com/settings/keys
2. Copy the public key content
3. Add it to your server's `~/.ssh/authorized_keys`:

```bash
ssh user@server_ip
echo "paste_your_github_public_key_here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

---

### Adding GitLab Public Keys

#### Method 1: Fetch from GitLab

Get your GitLab public keys:

```bash
# Fetch your GitLab public keys
curl https://gitlab.com/<YOUR_GITLAB_USERNAME>.keys
```

Example:
```bash
curl https://gitlab.com/sarojbhandari.keys
```

#### Method 2: Add to Server

```bash
# Fetch and add in one command
curl https://gitlab.com/<YOUR_GITLAB_USERNAME>.keys >> ~/.ssh/authorized_keys

# Example:
curl https://gitlab.com/sarojbhandari.keys >> ~/.ssh/authorized_keys
```

Fix permissions:
```bash
chmod 600 ~/.ssh/authorized_keys
```

#### Method 3: Manual GitLab Key Addition

1. Go to GitLab profile settings: https://gitlab.com/-/profile/keys
2. Copy the public key content
3. Add to your server:

```bash
ssh user@server_ip
echo "paste_your_gitlab_public_key_here" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
exit
```

---

### Batch Add Multiple Keys (GitHub + GitLab)

```bash
ssh user@server_ip

# Add GitHub keys
curl https://github.com/<YOUR_GITHUB_USERNAME>.keys >> ~/.ssh/authorized_keys

# Add GitLab keys
curl https://gitlab.com/<YOUR_GITLAB_USERNAME>.keys >> ~/.ssh/authorized_keys

# Fix permissions
chmod 600 ~/.ssh/authorized_keys

exit
```

---

## Complete Workflow Example

### Scenario: New Developer Setup

#### 1. Generate ED25519 Key (on your machine)

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_github -C "your_email@example.com"
```

#### 2. Add to SSH Agent

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github
```

#### 3. Add to GitHub

- Display key: `cat ~/.ssh/id_ed25519_github.pub`
- Go to https://github.com/settings/keys
- Click "New SSH key"
- Paste the key

#### 4. Deploy to Development Server

```bash
# Copy key to server
ssh-copy-id -i ~/.ssh/id_ed25519_github.pub dev@dev-server.com

# Test
ssh dev@dev-server.com
```

#### 5. Deploy to Production Server

```bash
# Copy key to production server
ssh-copy-id -i ~/.ssh/id_ed25519_github.pub prod@prod-server.com

# Test
ssh prod@prod-server.com
```

#### 6. Add GitLab Keys to Production Server

```bash
ssh prod@prod-server.com

# Fetch your GitLab keys
curl https://gitlab.com/your_username.keys >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

exit
```

#### 7. Auto-load on Login

Add to `~/.bashrc`:
```bash
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)" > /dev/null
    ssh-add ~/.ssh/id_ed25519_github
fi
```

---

## Troubleshooting

### Permission Denied (publickey)

```bash
# Check key permissions on local machine
ls -la ~/.ssh/id_ed25519*

# Should be:
# -rw------- (600) for private key
# -rw-r--r-- (644) for public key
```

### Fix on Server

```bash
ssh user@server_ip

# Verify authorized_keys exists and has correct permissions
ls -la ~/.ssh/authorized_keys  # Should be -rw------- (600)
ls -la ~/.ssh/                  # Should be drwx------ (700)

# Fix if needed
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

exit
```

### Check if Key is in SSH Agent

```bash
ssh-add -l  # Lists all keys
```

If your key isn't listed, add it:
```bash
ssh-add ~/.ssh/id_ed25519_github
```

### Debug SSH Connection

```bash
# Verbose output to see what's happening
ssh -vvv user@server_ip

# Shows which keys are being tried
```

### Key Not Found Error

```bash
# Make sure you specifying the right identity file
ssh -i ~/.ssh/id_ed25519_github user@server_ip

# Or add to SSH config
```

---

## SSH Config for Easy Management

Create or edit `~/.ssh/config`:

```bash
nano ~/.ssh/config
```

Add entries:

```
# GitHub
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github

# GitLab
Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519_gitlab

# Development Server
Host dev-server
    HostName dev.company.com
    User developer
    Port 22
    IdentityFile ~/.ssh/id_ed25519_dev

# Production Server
Host prod-server
    HostName prod.company.com
    User deploy
    Port 2222
    IdentityFile ~/.ssh/id_rsa_prod
    StrictHostKeyChecking accept-new
```

Now you can simply connect:
```bash
ssh github.com              # Uses GitHub key
ssh gitlab.com              # Uses GitLab key
ssh dev-server              # Uses dev key on dev.company.com
ssh prod-server             # Uses prod key on custom port
```

Fix SSH config permissions:
```bash
chmod 600 ~/.ssh/config
```

---

## Security Best Practices

1. **Use ED25519**: More secure and faster than RSA
2. **Always use passphrases**: Protects keys even if stolen
3. **Regular key rotation**: Generate new keys periodically
4. **Separate keys per use**: Different key for GitHub, servers, etc.
5. **Limit key permissions**: 
   - Private keys: `chmod 600`
   - Public keys: `chmod 644`
   - SSH directory: `chmod 700`
6. **Never share private keys**: Only share `.pub` files
7. **Use SSH Agent**: Avoids typing passphrases repeatedly
8. **Monitor authorized_keys**: Review who has access regularly
9. **Disable password auth**: After setting up key-based auth on servers

---

## Quick Reference

| Task | Command |
|------|---------|
| Generate ED25519 key | `ssh-keygen -t ed25519 -C "email@example.com"` |
| Generate RSA key | `ssh-keygen -t rsa -b 4096 -C "email@example.com"` |
| List keys | `ls ~/.ssh/` |
| View public key | `cat ~/.ssh/id_ed25519.pub` |
| Start SSH agent | `eval "$(ssh-agent -s)"` |
| Add key to agent | `ssh-add ~/.ssh/id_ed25519` |
| List agent keys | `ssh-add -l` |
| Remove key from agent | `ssh-add -d ~/.ssh/id_ed25519` |
| Copy to server | `ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host` |
| Fetch GitHub keys | `curl https://github.com/username.keys` |
| Fetch GitLab keys | `curl https://gitlab.com/username.keys` |

---
