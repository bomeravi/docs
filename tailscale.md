# Tailscale

A complete guide for installing and configuring **Tailscale** on **Ubuntu/Linux, Windows, and macOS**.

Tailscale creates a secure mesh VPN (built on WireGuard) between your devices — no port forwarding, no static IP needed.

---

## 📌 What is Tailscale?
Tailscale connects your servers, laptops, and containers into a private network (tailnet) using WireGuard under the hood. Each device gets a stable private IP and MagicDNS name, reachable from anywhere.

### Key Benefits
- ✔ No port forwarding
- ✔ No firewall changes (outbound-only connections)
- ✔ Point-to-point encrypted (WireGuard)
- ✔ MagicDNS — access devices by name
- ✔ Works on all major operating systems

---

## 📁 Table of Contents
- Requirements
- Ubuntu / Linux Setup
- Windows Setup
- macOS Setup
- Useful Commands
- Subnet Router (Expose LAN)
- Exit Node
- SSH via Tailscale
- ACLs & Access Control
- Troubleshooting

---

## 🧰 Requirements
- Tailscale account (Google/GitHub/Microsoft/email login)
- Terminal / PowerShell access
- Internet connection

---

## 🟩 Ubuntu / Linux Setup
### 1. Install Tailscale
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

### 2. Authenticate
```bash
sudo tailscale up
```
This prints a login URL — open it in a browser and sign in.

### 3. Check status
```bash
tailscale status
```

### 4. Get your Tailscale IP
```bash
tailscale ip -4
```

---

## 🟦 Windows Setup
### 1. Install
Download and run the installer from the Tailscale website, or via winget:
```powershell
winget install tailscale.tailscale
```

### 2. Authenticate
Open the Tailscale tray app and sign in, or via CLI:
```powershell
tailscale up
```

### 3. Check status
```powershell
tailscale status
```

---

## 🟨 macOS Setup
### 1. Install via Homebrew
```bash
brew install tailscale
```
Or install the **Tailscale.app** from the Mac App Store (needed for GUI/menu bar control).

### 2. Start service (Homebrew CLI variant)
```bash
sudo tailscaled install-system-daemon
sudo tailscale up
```

### 3. Check status
```bash
tailscale status
```

---

## ⚙️ Useful Commands
```bash
# Show status of tailnet devices
tailscale status

# Show this device's tailnet IPs
tailscale ip

# Ping another tailnet device
tailscale ping <device-name>

# Log in / re-authenticate
sudo tailscale up

# Log out
sudo tailscale logout

# Disconnect (keep config)
sudo tailscale down

# Reconnect
sudo tailscale up

# Show current config/preferences
tailscale status --json

# Set a custom hostname on the tailnet
sudo tailscale up --hostname=my-server

# Accept subnet routes advertised by others
sudo tailscale up --accept-routes

# Check version
tailscale version

# View network check / diagnostics
tailscale netcheck
```

---

## 🌐 Subnet Router (Expose LAN)
Advertise a local subnet so other tailnet devices can reach it.

### 1. Enable IP forwarding
```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-tailscale.conf
sudo sysctl -p /etc/sysctl.d/99-tailscale.conf
```

### 2. Advertise the route
```bash
sudo tailscale up --advertise-routes=192.168.1.0/24
```

### 3. Approve the route
Approve in the [Tailscale admin console](https://login.tailscale.com/admin/machines) under the device's route settings.

---

## 🚪 Exit Node
Route all internet traffic through a tailnet device.

### On the exit node server:
```bash
sudo tailscale up --advertise-exit-node
```
Approve it in the admin console.

### On the client device:
```bash
sudo tailscale up --exit-node=<exit-node-name-or-ip>
```

### Disable exit node
```bash
sudo tailscale up --exit-node=
```

---

## 🔐 SSH via Tailscale
Tailscale can act as an SSH server/broker without opening port 22 publicly.

### 1. Enable Tailscale SSH
```bash
sudo tailscale up --ssh
```

### 2. Connect from another tailnet device
```bash
tailscale ssh user@device-name
```

Access can be controlled via ACLs in the admin console.

---

## 🛡 ACLs & Access Control
Manage tailnet access policy from the [admin console → Access Controls](https://login.tailscale.com/admin/acls).

Example ACL snippet:
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["group:dev"],
      "dst": ["tag:server:*"]
    }
  ],
  "tagOwners": {
    "tag:server": ["group:admin"]
  }
}
```

Tag a device:
```bash
sudo tailscale up --advertise-tags=tag:server
```

---

## 🛠 Troubleshooting
### **Check daemon status**
```bash
sudo systemctl status tailscaled
```

### **Restart daemon**
```bash
sudo systemctl restart tailscaled
```

### **View logs**
```bash
journalctl -u tailscaled -f
```

### **Connectivity/NAT diagnostics**
```bash
tailscale netcheck
```

### **Re-authenticate after key expiry**
```bash
sudo tailscale up
```

### **Reset local state (force clean re-login)**
```bash
sudo tailscale logout
sudo systemctl restart tailscaled
sudo tailscale up
```
