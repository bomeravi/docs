# Local HTTPS with Custom Root CA

Set up trusted HTTPS for local domains without Let's Encrypt. Two approaches:

- **Part 1** — Quick single-domain self-signed cert
- **Part 2** — Custom Root CA (sign multiple domains, all trusted in one step)

Example domain: `sajiloapps.com`
Cert storage: `/etc/local-certs/{domain_name}`

---

## Part 1 — Quick Single Domain SSL

### 1. Add domain to `/etc/hosts`

```bash
sudo nano /etc/hosts
```

Add:

```text
127.0.0.1   sajiloapps.com
```

### 2. Create cert directory

```bash
sudo mkdir -p /etc/local-certs/sajiloapps.com
```

### 3. Generate self-signed cert

```bash
sudo openssl req -x509 -nodes -days 825 \
  -newkey rsa:2048 \
  -keyout /etc/local-certs/sajiloapps.com/privkey.pem \
  -out /etc/local-certs/sajiloapps.com/fullchain.pem \
  -subj "/CN=sajiloapps.com" \
  -addext "subjectAltName=DNS:sajiloapps.com,DNS:*.sajiloapps.com"
```

### 4. Trust cert in Ubuntu

```bash
sudo cp /etc/local-certs/sajiloapps.com/fullchain.pem \
  /usr/local/share/ca-certificates/sajiloapps.com.crt

sudo update-ca-certificates
```

### 5. Trust cert in Chrome / Chromium

Chrome uses the system NSS store on Linux:

```bash
# Install certutil if missing
sudo apt install libnss3-tools -y

# Trust for Chrome (user profile)
certutil -d sql:$HOME/.pki/nssdb -A \
  -t "CT,," \
  -n "sajiloapps.com" \
  -i /etc/local-certs/sajiloapps.com/fullchain.pem
```

Restart Chrome. Visit `https://sajiloapps.com` — padlock shows green.

### 6. Configure NGINX (example)

```bash
sudo nano /etc/nginx/sites-available/sajiloapps.com
```

```nginx
server {
    listen 443 ssl;
    server_name sajiloapps.com;

    ssl_certificate     /etc/local-certs/sajiloapps.com/fullchain.pem;
    ssl_certificate_key /etc/local-certs/sajiloapps.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

server {
    listen 80;
    server_name sajiloapps.com;
    return 301 https://$host$request_uri;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/sajiloapps.com \
  /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 6b. Configure Apache2 (example)

Enable required modules:

```bash
sudo a2enmod ssl proxy proxy_http
```

```bash
sudo nano /etc/apache2/sites-available/sajiloapps.com.conf
```

```apache
<VirtualHost *:443>
    ServerName sajiloapps.com

    SSLEngine on
    SSLCertificateFile    /etc/local-certs/sajiloapps.com/fullchain.pem
    SSLCertificateKeyFile /etc/local-certs/sajiloapps.com/privkey.pem

    ProxyPreserveHost On
    ProxyPass         / http://127.0.0.1:3000/
    ProxyPassReverse  / http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "https"
</VirtualHost>

<VirtualHost *:80>
    ServerName sajiloapps.com
    Redirect permanent / https://sajiloapps.com/
</VirtualHost>
```

```bash
sudo a2ensite sajiloapps.com.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### 6c. Configure HAProxy (example)

HAProxy needs cert + key merged into one PEM, then copied to HAProxy's cert directory:

```bash
sudo cat /etc/local-certs/sajiloapps.com/fullchain.pem \
         /etc/local-certs/sajiloapps.com/privkey.pem \
  | sudo tee /etc/local-certs/sajiloapps.com/haproxy.pem > /dev/null
sudo chmod 600 /etc/local-certs/sajiloapps.com/haproxy.pem

sudo mkdir -p /etc/haproxy/certs
sudo cp /etc/local-certs/sajiloapps.com/haproxy.pem \
        /etc/haproxy/certs/sajiloapps.com.pem
sudo chmod 600 /etc/haproxy/certs/sajiloapps.com.pem
```

Add to `/etc/haproxy/haproxy.cfg`:

```haproxy
frontend http_front
    bind *:80
    redirect scheme https code 301 if !{ ssl_fc }

frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/sajiloapps.com.pem
    default_backend app_backend

backend app_backend
    server app1 127.0.0.1:3000 check
```

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
```

---

## Part 2 — Custom Root CA (Recommended)

Create one Root CA, trust it once. Sign any local domain with it — no per-domain browser steps.

---

### Step 1 — Create Root CA

```bash
sudo mkdir -p /etc/local-certs/rootCA
cd /etc/local-certs/rootCA
```

Generate Root CA key:

```bash
sudo openssl genrsa -out rootCA.key 4096
```

Generate Root CA certificate (valid 10 years):

```bash
sudo openssl req -x509 -new -nodes \
  -key rootCA.key \
  -sha256 -days 3650 \
  -out rootCA.crt \
  -subj "/C=NP/ST=Bagmati/L=Kathmandu/O=SajiloApps Local CA/OU=Dev/CN=SajiloApps Root CA"
```

---

### Step 2 — Trust Root CA System-wide (Ubuntu)

```bash
sudo cp /etc/local-certs/rootCA/rootCA.crt \
  /usr/local/share/ca-certificates/SajiloApps-RootCA.crt

sudo update-ca-certificates
```

Verify:

```bash
update-ca-certificates --fresh 2>&1 | grep Sajiloapp
# or
openssl verify -CAfile /etc/local-certs/rootCA/rootCA.crt \
  /etc/local-certs/rootCA/rootCA.crt
```

---

### Step 3 — Trust Root CA in Chrome / Chromium

```bash
sudo apt install libnss3-tools -y

# Add to user NSS database
certutil -d sql:$HOME/.pki/nssdb -A \
  -t "CT,," \
  -n "SajiloApps Root CA" \
  -i /etc/local-certs/rootCA/rootCA.crt
```

Verify it was added:

```bash
certutil -d sql:$HOME/.pki/nssdb -L
```

Restart Chrome completely (`chrome://restart`).

---

### Step 4 — Trust Root CA in Firefox

Firefox uses its own cert store.

1. Open Firefox → Settings → Privacy & Security
2. Scroll to **Certificates** → click **View Certificates**
3. Tab **Authorities** → click **Import**
4. Select `/etc/local-certs/rootCA/rootCA.crt`
5. Check **Trust this CA to identify websites** → OK

Or via CLI (policy file method):

```bash
sudo mkdir -p /usr/lib/firefox/distribution

sudo tee /usr/lib/firefox/distribution/policies.json > /dev/null <<'EOF'
{
  "policies": {
    "Certificates": {
      "Install": [
        "/etc/local-certs/rootCA/rootCA.crt"
      ]
    }
  }
}
EOF
```

Restart Firefox.

---

### Step 5 — Create a Reusable Script to Sign Domains

Save as `/usr/local/bin/local-cert-sign`:

```bash
sudo tee /usr/local/bin/local-cert-sign > /dev/null <<'SCRIPT'
#!/bin/bash
# Usage: sudo local-cert-sign sajiloapps.com
set -e

DOMAIN="$1"
if [ -z "$DOMAIN" ]; then
  echo "Usage: $0 <domain>"
  exit 1
fi

CERT_DIR="/etc/local-certs/${DOMAIN}"
ROOT_CA_KEY="/etc/local-certs/rootCA/rootCA.key"
ROOT_CA_CRT="/etc/local-certs/rootCA/rootCA.crt"

mkdir -p "$CERT_DIR"

# Generate domain key
openssl genrsa -out "${CERT_DIR}/privkey.pem" 2048

# Create CSR config with SAN
cat > "${CERT_DIR}/csr.conf" <<EOF
[req]
default_bits = 2048
prompt = no
distinguished_name = dn
req_extensions = req_ext

[dn]
C=NP
ST=Bagmati
L=Kathmandu
O=SajiloApps Dev
CN=${DOMAIN}

[req_ext]
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
EOF

# Generate CSR
openssl req -new \
  -key "${CERT_DIR}/privkey.pem" \
  -out "${CERT_DIR}/domain.csr" \
  -config "${CERT_DIR}/csr.conf"

# Create extension file for signing
cat > "${CERT_DIR}/ext.conf" <<EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
DNS.1 = ${DOMAIN}
DNS.2 = *.${DOMAIN}
EOF

# Sign with Root CA (825 days — Chrome max)
openssl x509 -req \
  -in "${CERT_DIR}/domain.csr" \
  -CA "${ROOT_CA_CRT}" \
  -CAkey "${ROOT_CA_KEY}" \
  -CAcreateserial \
  -out "${CERT_DIR}/fullchain.pem" \
  -days 825 \
  -sha256 \
  -extfile "${CERT_DIR}/ext.conf"

echo ""
echo "Cert created:"
echo "  Key: ${CERT_DIR}/privkey.pem"
echo "  Cert: ${CERT_DIR}/fullchain.pem"
echo ""
echo "Verify:"
echo "  openssl verify -CAfile ${ROOT_CA_CRT} ${CERT_DIR}/fullchain.pem"
SCRIPT

sudo chmod +x /usr/local/bin/local-cert-sign
```

---

### Step 6 — Sign Domain with Root CA

```bash
sudo local-cert-sign sajiloapps.com
```

Verify cert chain:

```bash
openssl verify \
  -CAfile /etc/local-certs/rootCA/rootCA.crt \
  /etc/local-certs/sajiloapps.com/fullchain.pem
# Output: /etc/local-certs/sajiloapps.com/fullchain.pem: OK
```

Inspect cert:

```bash
openssl x509 -in /etc/local-certs/sajiloapps.com/fullchain.pem \
  -noout -text | grep -A2 "Subject Alternative"
```

---

### Step 7 — Add Domain to `/etc/hosts`

```bash
sudo nano /etc/hosts
```

```text
127.0.0.1   sajiloapps.com
127.0.0.1   *.sajiloapps.com
```

> `/etc/hosts` does not support wildcard. Add each subdomain explicitly if needed:
> `127.0.0.1   api.sajiloapps.com`

---

### Step 8 — Configure NGINX

```bash
sudo nano /etc/nginx/sites-available/sajiloapps.com
```

```nginx
server {
    listen 443 ssl;
    server_name sajiloapps.com *.sajiloapps.com;

    ssl_certificate     /etc/local-certs/sajiloapps.com/fullchain.pem;
    ssl_certificate_key /etc/local-certs/sajiloapps.com/privkey.pem;

    ssl_protocols       TLSv1.2 TLSv1.3;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
    }
}

server {
    listen 80;
    server_name sajiloapps.com *.sajiloapps.com;
    return 301 https://$host$request_uri;
}
```

```bash
sudo ln -s /etc/nginx/sites-available/sajiloapps.com \
  /etc/nginx/sites-enabled/

sudo nginx -t
sudo systemctl reload nginx
```

### Step 8b — Configure Apache2

Enable required modules:

```bash
sudo a2enmod ssl proxy proxy_http
```

```bash
sudo nano /etc/apache2/sites-available/sajiloapps.com.conf
```

```apache
<VirtualHost *:443>
    ServerName sajiloapps.com
    ServerAlias *.sajiloapps.com

    SSLEngine on
    SSLCertificateFile    /etc/local-certs/sajiloapps.com/fullchain.pem
    SSLCertificateKeyFile /etc/local-certs/sajiloapps.com/privkey.pem

    SSLProtocol           all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite        HIGH:!aNULL:!MD5

    ProxyPreserveHost On
    ProxyPass         / http://127.0.0.1:3000/
    ProxyPassReverse  / http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "https"
    RequestHeader set X-Real-IP         "%{REMOTE_ADDR}s"
</VirtualHost>

<VirtualHost *:80>
    ServerName sajiloapps.com
    ServerAlias *.sajiloapps.com
    Redirect permanent / https://sajiloapps.com/
</VirtualHost>
```

```bash
sudo a2ensite sajiloapps.com.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### Step 8c — Configure HAProxy

HAProxy needs cert + key merged into one PEM, then copied to HAProxy's cert directory:

```bash
sudo cat /etc/local-certs/sajiloapps.com/fullchain.pem \
         /etc/local-certs/sajiloapps.com/privkey.pem \
  | sudo tee /etc/local-certs/sajiloapps.com/haproxy.pem > /dev/null
sudo chmod 600 /etc/local-certs/sajiloapps.com/haproxy.pem

sudo mkdir -p /etc/haproxy/certs
sudo cp /etc/local-certs/sajiloapps.com/haproxy.pem \
        /etc/haproxy/certs/sajiloapps.com.pem
sudo chmod 600 /etc/haproxy/certs/sajiloapps.com.pem
```

Add to `/etc/haproxy/haproxy.cfg`:

```haproxy
frontend http_front
    bind *:80
    redirect scheme https code 301 if !{ ssl_fc }

frontend https_front
    bind *:443 ssl crt /etc/haproxy/certs/sajiloapps.com.pem
    http-request set-header X-Forwarded-Proto https
    http-request set-header X-Real-IP %[src]
    default_backend app_backend

backend app_backend
    option forwardfor
    server app1 127.0.0.1:3000 check
```

```bash
sudo haproxy -c -f /etc/haproxy/haproxy.cfg
sudo systemctl reload haproxy
```

---

## Certificate File Layout

```text
/etc/local-certs/
├── rootCA/
│   ├── rootCA.key        ← keep private, never share
│   ├── rootCA.crt        ← import into browsers / OS
│   └── rootCA.srl        ← serial tracker (auto-created)
└── sajiloapps.com/
    ├── privkey.pem       ← domain private key
    ├── fullchain.pem     ← domain certificate (CA-signed)
    ├── domain.csr        ← CSR (can delete after signing)
    ├── csr.conf          ← CSR config
    └── ext.conf          ← signing extensions
```

---

## Add Another Domain Later

```bash
# 1. Sign new domain
sudo local-cert-sign anotherdomain.com

# 2. Add to /etc/hosts
echo "127.0.0.1   anotherdomain.com" | sudo tee -a /etc/hosts

# 3a. NGINX — copy pattern from Step 8, change domain + port
# 3b. Apache2 — copy pattern from Step 8b, change domain + port
# 3c. HAProxy — combine new cert, update haproxy.cfg backend

# No browser steps needed — Root CA already trusted
```

---

## Renew Domain Certificate

### Check Expiry

```bash
openssl x509 -enddate -noout \
  -in /etc/local-certs/sajiloapps.com/fullchain.pem
```

Check days remaining:

```bash
openssl x509 -checkend $((30 * 86400)) -noout \
  -in /etc/local-certs/sajiloapps.com/fullchain.pem \
  && echo "OK — more than 30 days left" \
  || echo "EXPIRING — renew now"
```

### Renew if Less Than 30 Days

```bash
if ! openssl x509 -checkend $((30 * 86400)) -noout \
     -in /etc/local-certs/sajiloapps.com/fullchain.pem; then
  sudo local-cert-sign sajiloapps.com
  echo "Certificate renewed."
else
  echo "Certificate still valid — skipping."
fi
```

### Force Renew (Skip Expiry Check)

```bash
sudo local-cert-sign sajiloapps.com
```

### Post-Renewal Steps

After renewing, update HAProxy's combined PEM and reload all active servers:

```bash
# Rebuild HAProxy PEM
sudo cat /etc/local-certs/sajiloapps.com/fullchain.pem \
         /etc/local-certs/sajiloapps.com/privkey.pem \
  | sudo tee /etc/local-certs/sajiloapps.com/haproxy.pem > /dev/null
sudo chmod 600 /etc/local-certs/sajiloapps.com/haproxy.pem

sudo cp /etc/local-certs/sajiloapps.com/haproxy.pem \
        /etc/haproxy/certs/sajiloapps.com.pem
sudo chmod 600 /etc/haproxy/certs/sajiloapps.com.pem

# Reload servers (run only for whichever is active)
sudo systemctl reload nginx
sudo systemctl reload apache2
sudo systemctl reload haproxy
```

> NGINX and Apache2 read cert files on reload — no path change needed.
> HAProxy requires the combined PEM to be rebuilt and copied each time.

---

## Troubleshooting

| Issue | Fix |
|---|---|
| Chrome shows "NET::ERR_CERT_AUTHORITY_INVALID" | Re-run `certutil` step, restart Chrome fully |
| Chrome shows "NET::ERR_CERT_COMMON_NAME_INVALID" | Cert missing SAN — regenerate with `subjectAltName` |
| `update-ca-certificates` shows 0 added | File must end in `.crt` in `/usr/local/share/ca-certificates/` |
| Firefox still untrusted | Firefox ignores system store — import manually in Firefox |
| Cert valid period warning | Chrome max is 825 days — do not exceed |
| NGINX `[emerg] cannot load certificate` | Check path, check file permissions (`sudo chmod 644 fullchain.pem`) |
| Apache2 `SSLCertificateFile: file not found` | Check path, verify `sudo a2enmod ssl` was run |
| Apache2 `AH01630: client denied` | Enable `proxy` and `proxy_http` modules: `sudo a2enmod proxy proxy_http` |
| HAProxy `cannot load certificate` | haproxy.pem must contain fullchain + privkey concatenated; check `chmod 600` on both `/etc/local-certs/.../haproxy.pem` and `/etc/haproxy/certs/sajiloapps.com.pem` |

---

## Quick Reference

```bash
# Create root CA (once)
sudo openssl genrsa -out /etc/local-certs/rootCA/rootCA.key 4096
sudo openssl req -x509 -new -nodes -key /etc/local-certs/rootCA/rootCA.key \
  -sha256 -days 3650 -out /etc/local-certs/rootCA/rootCA.crt \
  -subj "/CN=SajiloApps Root CA"

# Trust root CA (once per machine)
sudo cp /etc/local-certs/rootCA/rootCA.crt /usr/local/share/ca-certificates/SajiloApps-RootCA.crt
sudo update-ca-certificates
certutil -d sql:$HOME/.pki/nssdb -A -t "CT,," -n "SajiloApps Root CA" \
  -i /etc/local-certs/rootCA/rootCA.crt

# Sign new domain
sudo local-cert-sign sajiloapps.com

# Add to hosts
echo "127.0.0.1 sajiloapps.com" | sudo tee -a /etc/hosts
```
