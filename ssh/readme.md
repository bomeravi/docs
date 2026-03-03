# Install SSH

Install and Configure SSH on Ubuntu Server
This guide explains how to install, enable, and secure SSH on an Ubuntu server.

---

## 1. Update System Packages

```bash
sudo apt update && sudo apt upgrade -y
```

---

## 2. Install OpenSSH Server

```bash
sudo apt install openssh-server -y
```

---

## 3. Check SSH Service Status

```bash
sudo systemctl status ssh
```

If not running, start it:

```bash
sudo systemctl start ssh
```

Enable SSH to start on boot:

```bash
sudo systemctl enable ssh
```

---

## 4. Verify SSH is Listening

```bash
sudo ss -tulnp | grep ssh
```

You should see port `22` in LISTEN state.

---

## 5. Allow SSH Through Firewall (UFW)
Not for cloud providers, on cloud providers use external firewall outside instance.
```bash
sudo ufw allow ssh
sudo ufw enable
sudo ufw status
```

---

## 6. Connect to Server via SSH

From your local machine:

```bash
ssh username@your_server_ip
```

Example:

```bash
ssh ubuntu@192.168.1.10
```

---

## 7. (Optional but Recommended) Change SSH Port

Edit SSH config:

```bash
sudo nano /etc/ssh/sshd_config
```

Find:

```
#Port 22
```

Change to:

```
Port 2222
```

Apply changes:

```bash
sudo systemctl restart ssh
```

Update firewall:

```bash
sudo ufw allow 2222/tcp
```

---

## 8. (Optional) Disable Root Login

Edit config:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:

```
PermitRootLogin no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

---

## 9. (Optional) Enable Key-Based Authentication

### Generate SSH Key (on local machine)

```bash
ssh-keygen -t ed25519
```

### Copy key to server

```bash
ssh-copy-id username@your_server_ip
```

---

## 10. (Optional) Disable Password Authentication

⚠️ Do this only after confirming key login works.

Edit config:

```bash
sudo nano /etc/ssh/sshd_config
```

Set:

```
PasswordAuthentication no
```

Restart:

```bash
sudo systemctl restart ssh
```

---

## 11. Troubleshooting

### SSH not starting

```bash
sudo journalctl -u ssh
```

### Port blocked

```bash
sudo ufw status
```

### Check config errors

```bash
sudo sshd -t
```

---

## 12. Useful Commands

Restart SSH:

```bash
sudo systemctl restart ssh
```

Stop SSH:

```bash
sudo systemctl stop ssh
```

Disable SSH:

```bash
sudo systemctl disable ssh
```

---

## Security Tips

* Use SSH keys instead of passwords
* Change default port (optional)
* Disable root login
* Regularly update server

---

## Done ✅

Ubuntu server is now ready with SSH access.
