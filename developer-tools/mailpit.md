# Mailpit

> **Mailpit** is a lightweight, self-hosted email testing tool for developers. It acts as a local SMTP server that captures all outgoing emails from your application and displays them in a clean web UI — without ever sending them to real recipients.

------------------------------------------------------------------------

## How Mailpit Works

```
Your App  →  SMTP (port 1025)  →  Mailpit  →  Web UI (port 8025)
```

1. Your application sends emails via SMTP to Mailpit's local SMTP server (default port `1025`).
2. Mailpit intercepts and stores the messages — nothing is forwarded to real email addresses.
3. You view, inspect, and debug emails through the Mailpit web UI at `http://localhost:8025`.

**Key features:**
- Catches all outgoing SMTP traffic regardless of recipient address
- Web UI with full email preview (HTML, plain text, raw source, headers)
- Search and filter emails
- REST API for automated testing
- Optional SMTP authentication
- Optional HTTPS and basic auth for the web UI

------------------------------------------------------------------------

## 1️⃣ Installation

### Ubuntu / Debian

```bash
# Download the latest binary
curl -LO https://github.com/axllent/mailpit/releases/latest/download/mailpit-linux-amd64.tar.gz

# Extract
tar -xzf mailpit-linux-amd64.tar.gz

# Move to system path
sudo mv mailpit /usr/local/bin/mailpit
sudo chmod +x /usr/local/bin/mailpit

# Verify
mailpit --version
```

**Run as a systemd service:**

```bash
sudo tee /etc/systemd/system/mailpit.service > /dev/null <<EOF
[Unit]
Description=Mailpit email testing service
After=network.target

[Service]
ExecStart=/usr/local/bin/mailpit
Restart=always
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now mailpit
sudo systemctl status mailpit
```

------------------------------------------------------------------------

### Windows

**Option 1 — Winget (recommended):**

```powershell
winget install axllent.mailpit
```

**Option 2 — Manual download:**

1. Download `mailpit-windows-amd64.zip` from [GitHub Releases](https://github.com/axllent/mailpit/releases/latest)
2. Extract and place `mailpit.exe` in a directory on your `PATH`
3. Run it:

```powershell
mailpit.exe
```

**Run as a Windows Service (NSSM):**

```powershell
# Install NSSM first: https://nssm.cc/
nssm install Mailpit "C:\path\to\mailpit.exe"
nssm start Mailpit
```

------------------------------------------------------------------------

### macOS

**Option 1 — Homebrew (recommended):**

```bash
brew install mailpit
```

Start as a background service:

```bash
brew services start mailpit
```

**Option 2 — Manual download:**

```bash
# Apple Silicon
curl -LO https://github.com/axllent/mailpit/releases/latest/download/mailpit-darwin-arm64.tar.gz
tar -xzf mailpit-darwin-arm64.tar.gz

# Intel
curl -LO https://github.com/axllent/mailpit/releases/latest/download/mailpit-darwin-amd64.tar.gz
tar -xzf mailpit-darwin-amd64.tar.gz

sudo mv mailpit /usr/local/bin/mailpit
mailpit --version
```

------------------------------------------------------------------------

## 2️⃣ Default Ports

| Service | Default Port |
|---|---|
| SMTP server | `1025` |
| Web UI / HTTP API | `8025` |

Point your application's SMTP settings to:
- **Host:** `localhost` (or server IP)
- **Port:** `1025`
- **No authentication, no TLS** (development only)

------------------------------------------------------------------------

## 3️⃣ Reverse Proxy Setup

Use domain: **`mailpit.sajiloapps.com`** → proxies to `http://127.0.0.1:8025`

> Make sure your DNS A record for `mailpit.sajiloapps.com` points to your server's public IP.

------------------------------------------------------------------------

### Apache2

**Install Apache2:**

```bash
sudo apt install apache2 -y
sudo a2enmod proxy proxy_http proxy_wstunnel rewrite headers ssl
sudo systemctl restart apache2
```

#### HTTP

Create `/etc/apache2/sites-available/mailpit.conf`:

```apache
<VirtualHost *:80>
    ServerName mailpit.sajiloapps.com

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8025/
    ProxyPassReverse / http://127.0.0.1:8025/

    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-Host "mailpit.sajiloapps.com"

    ErrorLog ${APACHE_LOG_DIR}/mailpit_error.log
    CustomLog ${APACHE_LOG_DIR}/mailpit_access.log combined
</VirtualHost>
```

```bash
sudo a2ensite mailpit.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

#### HTTPS

Install Certbot and obtain a certificate first:

```bash
sudo apt install certbot python3-certbot-apache -y
sudo certbot --apache -d mailpit.sajiloapps.com
```

Or configure manually — create `/etc/apache2/sites-available/mailpit-ssl.conf`:

```apache
<VirtualHost *:80>
    ServerName mailpit.sajiloapps.com
    Redirect permanent / https://mailpit.sajiloapps.com/
</VirtualHost>

<VirtualHost *:443>
    ServerName mailpit.sajiloapps.com

    SSLEngine on
    SSLCertificateFile    /etc/letsencrypt/live/mailpit.sajiloapps.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/mailpit.sajiloapps.com/privkey.pem

    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:8025/
    ProxyPassReverse / http://127.0.0.1:8025/

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Forwarded-Host "mailpit.sajiloapps.com"

    ErrorLog ${APACHE_LOG_DIR}/mailpit_error.log
    CustomLog ${APACHE_LOG_DIR}/mailpit_access.log combined
</VirtualHost>
```

```bash
sudo a2ensite mailpit-ssl.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

------------------------------------------------------------------------

### Nginx

**Install Nginx:**

```bash
sudo apt install nginx -y
```

#### HTTP

Create `/etc/nginx/sites-available/mailpit`:

```nginx
server {
    listen 80;
    server_name mailpit.sajiloapps.com;

    location / {
        proxy_pass         http://127.0.0.1:8025;
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # WebSocket support (Mailpit uses SSE/WS for live updates)
        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 86400;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/mailpit /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

#### HTTPS

Obtain a certificate:

```bash
sudo apt install certbot python3-certbot-nginx -y
sudo certbot --nginx -d mailpit.sajiloapps.com
```

Or configure manually — update `/etc/nginx/sites-available/mailpit`:

```nginx
server {
    listen 80;
    server_name mailpit.sajiloapps.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name mailpit.sajiloapps.com;

    ssl_certificate     /etc/letsencrypt/live/mailpit.sajiloapps.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mailpit.sajiloapps.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass         http://127.0.0.1:8025;
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;

        proxy_set_header Upgrade    $http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_read_timeout 86400;
    }
}
```

```bash
sudo nginx -t
sudo systemctl reload nginx
```

------------------------------------------------------------------------

### HAProxy

**Install HAProxy:**

```bash
sudo apt install haproxy -y
```

#### HTTP

Edit `/etc/haproxy/haproxy.cfg` and append:

```haproxy
frontend mailpit_http
    bind *:80
    option http-server-close
    option forwardfor
    http-request set-header X-Forwarded-Proto http

    acl host_mailpit hdr(host) -i mailpit.sajiloapps.com
    use_backend mailpit_backend if host_mailpit

backend mailpit_backend
    balance roundrobin
    option httpchk GET /
    server mailpit 127.0.0.1:8025 check
```

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
```

#### HTTPS

Combine your certificate and key into a single `.pem` for HAProxy:

```bash
sudo mkdir -p /etc/haproxy/certs
sudo cat /etc/letsencrypt/live/mailpit.sajiloapps.com/fullchain.pem \
         /etc/letsencrypt/live/mailpit.sajiloapps.com/privkey.pem \
    | sudo tee /etc/haproxy/certs/mailpit.sajiloapps.com.pem > /dev/null
sudo chmod 600 /etc/haproxy/certs/mailpit.sajiloapps.com.pem
```

Edit `/etc/haproxy/haproxy.cfg` and append:

```haproxy
frontend mailpit_http
    bind *:80
    redirect scheme https code 301 if { hdr(host) -i mailpit.sajiloapps.com }

frontend mailpit_https
    bind *:443 ssl crt /etc/haproxy/certs/mailpit.sajiloapps.com.pem
    option http-server-close
    option forwardfor
    http-request set-header X-Forwarded-Proto https

    acl host_mailpit hdr(host) -i mailpit.sajiloapps.com
    use_backend mailpit_backend if host_mailpit

backend mailpit_backend
    balance roundrobin
    option httpchk GET /
    server mailpit 127.0.0.1:8025 check
```

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
```

------------------------------------------------------------------------

## 4️⃣ Verify Setup

```bash
# Check Mailpit is running
curl http://127.0.0.1:8025

# Check via domain (HTTP)
curl http://mailpit.sajiloapps.com

# Check via domain (HTTPS)
curl https://mailpit.sajiloapps.com
```

Open the web UI in your browser:

- HTTP: `http://mailpit.sajiloapps.com`
- HTTPS: `https://mailpit.sajiloapps.com`

------------------------------------------------------------------------

## 5️⃣ Useful Mailpit Flags

| Flag | Default | Description |
|---|---|---|
| `--smtp` | `0.0.0.0:1025` | SMTP bind address |
| `--listen` | `0.0.0.0:8025` | Web UI bind address |
| `--max` | `500` | Max stored messages |
| `--smtp-auth-file` | — | Enable SMTP authentication |
| `--ui-auth-file` | — | Enable web UI basic auth |
| `--ui-tls-cert` | — | TLS cert for web UI |
| `--ui-tls-key` | — | TLS key for web UI |

Example with options:

```bash
mailpit --smtp 0.0.0.0:1025 --listen 0.0.0.0:8025 --max 1000
```
