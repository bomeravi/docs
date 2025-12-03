# Cloudflared / Cloudflare Tunnel — Complete Setup Guide

A complete, production-ready guide for installing and configuring **Cloudflare Tunnel (cloudflared)** on **Ubuntu/Linux, Windows, and macOS**.

Securely expose local services to the internet without opening firewall ports.

---

## 📌 What is Cloudflare Tunnel?
Cloudflare Tunnel allows you to expose local applications (web servers, APIs, SSH, containers, etc.) to the internet securely using an encrypted outbound-only connection.

### Key Benefits
- ✔ No port forwarding
- ✔ No firewall changes
- ✔ Zero Trust support
- ✔ Works on all major operating systems

---

## 📁 Table of Contents
- Requirements
- Ubuntu / Linux Setup
- Windows Setup
- macOS Setup
- Quick Tunnel (No Login)
- SSH via Cloudflare Tunnel
- Expose Docker Services
- Multiple Services in One Tunnel
- Troubleshooting

---

## 🧰 Requirements
- Cloudflare Account
- Domain added to Cloudflare DNS
- Terminal / PowerShell access
- Internet connection

---

## 🟩 Ubuntu / Linux Setup
### 1. Install cloudflared

#### **Method A — Debian Package**
```bash
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

#### **Method B — APT Repository (recommended)**
```bash
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main" | sudo tee /etc/apt/sources.list.d/cloudflare.list
sudo apt update
sudo apt install cloudflared
```

### 2. Authenticate
```bash
cloudflared tunnel login
```

### 3. Create the Tunnel
```bash
cloudflared tunnel create my-tunnel
```

### 4. Create config file
```bash
sudo nano /etc/cloudflared/config.yml
```

#### Example config:
```yaml
tunnel: <UUID>
credentials-file: /root/.cloudflared/<UUID>.json

ingress:
  - hostname: app.example.com
    service: http://localhost:8080
  - service: http_status:404
```

### 5. Enable as service
```bash
sudo cloudflared service install
sudo systemctl enable cloudflared
sudo systemctl start cloudflared
```

---

## 🟦 Windows Setup
### 1. Install cloudflared
Download installer from the Cloudflare docs or place the binary inside:
```
C:\Program Files\cloudflared\
```

### 2. Authenticate
```powershell
cloudflared tunnel login
```

### 3. Create Tunnel
```powershell
cloudflared tunnel create my-tunnel
```

### 4. Create config file
Location:
```
C:\Users\<YOU>\.cloudflared\config.yml
```

#### Example:
```yaml
tunnel: <UUID>
credentials-file: C:\Users\YOU\.cloudflared\<UUID>.json

ingress:
  - hostname: win.example.com
    service: http://localhost:5000
  - service: http_status:404
```

### 5. Run Tunnel
```powershell
cloudflared tunnel run my-tunnel
```

To run in background:
- Use **Task Scheduler**, or
- Install as service using **NSSM**

---

## 🟨 macOS Setup
### 1. Install via Homebrew
```bash
brew install cloudflared
```

### 2. Authenticate
```bash
cloudflared tunnel login
```

### 3. Create Tunnel
```bash
cloudflared tunnel create my-tunnel
```

### 4. Config file location
```
~/.cloudflared/config.yml
```

#### Example:
```yaml
tunnel: <UUID>
credentials-file: /Users/you/.cloudflared/<UUID>.json

ingress:
  - hostname: mac.example.com
    service: http://localhost:3000
  - service: http_status:404
```

---

## ⚡ Quick Tunnel (No Login Required)
Great for quick testing:
```bash
cloudflared tunnel --url http://localhost:3000
```
Output example:
```
https://random1234.trycloudflare.com
```

---

## 🔐 SSH via Cloudflare Tunnel
Add to config:
```yaml
ingress:
  - hostname: ssh.example.com
    service: ssh://localhost:22
  - service: http_status:404
```

Connect:
```bash
cloudflared access ssh --hostname ssh.example.com
```

---

## 🐳 Expose Docker Services
Example config:
```yaml
ingress:
  - hostname: docker.example.com
    service: http://host.docker.internal:8080
  - service: http_status:404
```

---

## 🌐 Multiple Services in One Tunnel
```yaml
ingress:
  - hostname: api.example.com
    service: http://localhost:8000

  - hostname: web.example.com
    service: http://localhost:3000

  - hostname: monitor.example.com
    service: http://localhost:9090

  - service: http_status:404
```

---

## 🌍 Link Subdomain to Cloudflare Tunnel
To connect any subdomain (e.g., `app.example.com`) to your Cloudflare Tunnel, follow these steps:

### **1. Get Your Tunnel UUID**
Run:
```bash
cloudflared tunnel list
```
Copy the `Tunnel ID (UUID)`.

### **2. Create DNS CNAME Record Automatically**
Use this command:
```bash
cloudflared tunnel route dns <TUNNEL_NAME> sub.example.com
```
Example:
```bash
cloudflared tunnel route dns my-tunnel app.example.com
```
This creates a DNS CNAME record:
```
app.example.com → <UUID>.cfargotunnel.com
```

### **3. Reference the subdomain in config.yml**
```yaml
ingress:
  - hostname: app.example.com
    service: http://localhost:8080
  - service: http_status:404
```

### **4. Restart tunnel**
```bash
sudo systemctl restart cloudflared
```

Your subdomain is now linked and online through Cloudflare Tunnel.

---

## 🛠 Troubleshooting
### **QUIC Blocked**
```bash
cloudflared --protocol http2 tunnel run my-tunnel
```

### **Reset certificate**
```bash
rm ~/.cloudflared/cert.pem
cloudflared tunnel login
```

### **DNS not resolving**
Create CNAME:
```
<UUID>.cfargotunnel.com
```

### **Systemd errors**
```bash
journalctl -u cloudflared
sudo systemctl restart cloudflared
```