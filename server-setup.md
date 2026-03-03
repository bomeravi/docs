# Server Setup (Digitalocean)

Creating and Using `ubuntu` User on DigitalOcean (Ubuntu 24.04 LTS)
This document explains how to migrate from **root login** to a secure, non-root user named **`ubuntu`**, and why each command is used.

---

## 1. Create the ubuntu user

```bash
adduser ubuntu
```

Creates a normal Linux user.  
The password is used only for `sudo`, not SSH (if key-based login is enabled).

---

## 2. Grant sudo privileges

```bash
usermod -aG sudo ubuntu
```

Adds the user to the `sudo` group so administrative commands can be run safely.

Verify:
```bash
groups ubuntu
```

Expected:
```
ubuntu : ubuntu sudo users
```

---

## 3. Copy SSH keys from root to ubuntu

```bash
rsync --archive --chown=ubuntu:ubuntu /root/.ssh /home/ubuntu
```

### What this does
- Copies SSH configuration and keys from `root`
- Preserves permissions and structure
- Forces correct ownership for SSH to work

### Why this is required
SSH **rejects keys** if they are owned by another user or have unsafe permissions.

---

## 4. Fix permissions (critical for SSH)

```bash
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys
```

SSH will refuse to authenticate if these permissions are too open.

---

## 5. Test login as ubuntu

Open a new terminal:
```bash
ssh ubuntu@SERVER_IP
```

Verify identity:
```bash
whoami
```

Verify sudo:
```bash
sudo whoami
```

Expected output:
```
root
```

---

## 6. Disable root SSH login (recommended)

Edit SSH config:
```bash
sudo nano /etc/ssh/sshd_config
```

Set:
```text
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:
```bash
sudo systemctl restart ssh
```

---

## 7. (Optional) Lock root account completely

```bash
sudo passwd -l root
```

Prevents root from logging in locally or remotely.

---

## Final Security State

| Item | Status |
|----|----|
| Root SSH login | Disabled |
| Primary admin user | ubuntu |
| Authentication | SSH key only |
| Privilege escalation | sudo |
| OS | Ubuntu 24.04 LTS |

---

## Best Practice Notes

- Never deploy apps as root
- Use `sudo` only when required
- Keep SSH key-only authentication
- Rotate keys periodically

---

**File:** `server-setup.md`
