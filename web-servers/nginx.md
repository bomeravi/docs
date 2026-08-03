# NGINX

Install, configure, and operate NGINX on Ubuntu, RHEL, and macOS — with ready-to-copy
server blocks for static hosting, PHP sites, reverse proxying, SPAs, load balancing,
HTTPS, and WebSockets.

> NGINX is an event-driven web server, reverse proxy, and load balancer. It handles
> static files itself and passes dynamic requests to an application (PHP-FPM, Node,
> Gunicorn, Java) over HTTP or a Unix socket.

---

## 1. Installation

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y nginx
sudo systemctl enable --now nginx
```

For the latest mainline release from the official NGINX repository:

```bash
sudo apt install -y curl gnupg2 ca-certificates lsb-release ubuntu-keyring
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
  | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/mainline/ubuntu $(lsb_release -cs) nginx" \
  | sudo tee /etc/apt/sources.list.d/nginx.list
sudo apt update && sudo apt install -y nginx
```

### RHEL / CentOS / Rocky

```bash
sudo dnf install -y nginx
sudo systemctl enable --now nginx
```

### macOS

```bash
brew install nginx
brew services start nginx
```

### Verify

```bash
nginx -v
systemctl status nginx --no-pager
curl -I http://localhost
```

Expected:

```text
HTTP/1.1 200 OK
Server: nginx/1.24.0
```

> ⚠️ Port 80 conflicts with Apache. If Apache is already running:
> `sudo systemctl disable --now apache2` before starting NGINX.

---

## 2. Config File Layout

| Path                            | Purpose                                  |
| ------------------------------- | ---------------------------------------- |
| `/etc/nginx/nginx.conf`         | Main config; global/`http` block          |
| `/etc/nginx/sites-available/`   | All site configs (Debian/Ubuntu)          |
| `/etc/nginx/sites-enabled/`     | Symlinks to active sites                  |
| `/etc/nginx/conf.d/`            | Drop-in configs (RHEL uses this only)     |
| `/etc/nginx/snippets/`          | Reusable fragments to `include`           |
| `/var/www/`                     | Default web root                          |
| `/var/log/nginx/`               | `access.log` and `error.log`              |

Enable and disable sites:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

> On RHEL there is no `sites-available`/`sites-enabled` — put site files directly in
> `/etc/nginx/conf.d/example.com.conf`.

---

## 3. Service Commands

```bash
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx          # graceful, no dropped connections
sudo systemctl status nginx --no-pager
sudo systemctl enable nginx          # start on boot
```

Test the config **before** every reload:

```bash
sudo nginx -t
sudo nginx -T                        # test and dump the full effective config
```

Expected:

```text
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## 4. Scenario: Static Website Hosting

The simplest case — plain HTML/CSS/JS served from disk.

```bash
sudo mkdir -p /var/www/example.com/html
sudo chown -R $USER:$USER /var/www/example.com/html
echo "<h1>example.com works</h1>" > /var/www/example.com/html/index.html
```

`/etc/nginx/sites-available/example.com`:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name example.com www.example.com;
    root /var/www/example.com/html;
    index index.html index.htm;

    location / {
        try_files $uri $uri/ =404;
    }

    # Cache static assets for a year
    location ~* \.(jpg|jpeg|png|gif|ico|svg|woff2?|css|js)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }

    access_log /var/log/nginx/example.com.access.log;
    error_log  /var/log/nginx/example.com.error.log;
}
```

Enable it:

```bash
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
```

---

## 5. Scenario: PHP Site (PHP-FPM)

For Laravel, WordPress, or any PHP app. Requires `php-fpm` (see [LAMP Setup](../lamp-setup.md)).

```bash
sudo apt install -y php8.4-fpm
sudo systemctl enable --now php8.4-fpm
```

`/etc/nginx/sites-available/app.example.com`:

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /var/www/app/public;          # Laravel: /public, WordPress: site root
    index index.php index.html;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.4-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }

    # Never serve dotfiles or hidden config
    location ~ /\.(?!well-known).* {
        deny all;
    }

    client_max_body_size 64M;          # allow larger uploads
}
```

Set ownership so PHP-FPM can read the files:

```bash
sudo chown -R www-data:www-data /var/www/app
sudo find /var/www/app -type d -exec chmod 755 {} \;
sudo find /var/www/app -type f -exec chmod 644 {} \;
```

> Swap the socket to `/run/php/php8.3-fpm.sock` to run this one site on a different
> PHP version.

---

## 6. Scenario: Reverse Proxy

Put NGINX in front of an app listening on localhost — Node, Django/Gunicorn, Spring Boot,
Jenkins, or anything else.

```nginx
server {
    listen 80;
    server_name api.example.com;

    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host  $host;

        proxy_connect_timeout 60s;
        proxy_send_timeout    60s;
        proxy_read_timeout    60s;
    }
}
```

> ⚠️ Bind your app to `127.0.0.1`, not `0.0.0.0`, so it is only reachable through NGINX.

### Proxy a subpath

```nginx
location /api/ {
    proxy_pass http://127.0.0.1:3000/;   # trailing slash strips /api/
}
```

### WebSockets

```nginx
location /ws/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade    $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host       $host;
    proxy_read_timeout 3600s;            # keep long-lived sockets open
}
```

---

## 7. Scenario: SPA (React, Vue, Angular)

Client-side routers need every unknown path to fall back to `index.html`.

```nginx
server {
    listen 80;
    server_name app.example.com;
    root /var/www/react-app/dist;        # CRA uses /build, Vite uses /dist
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;   # the SPA fallback
    }

    # Hashed build assets never change — cache hard
    location /assets/ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Never cache the entry point
    location = /index.html {
        add_header Cache-Control "no-cache, must-revalidate";
    }

    # Optional: proxy the API to avoid CORS
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

---

## 8. Scenario: Load Balancing

Define an `upstream` in the `http` block (or a file in `conf.d/`):

```nginx
upstream backend {
    least_conn;                          # or ip_hash / round-robin (default)

    server 10.0.0.11:8080 weight=3;
    server 10.0.0.12:8080;
    server 10.0.0.13:8080 backup;        # only used if others are down

    keepalive 32;
}

server {
    listen 80;
    server_name app.example.com;

    location / {
        proxy_pass http://backend;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        proxy_next_upstream error timeout http_502 http_503;
    }
}
```

| Method        | Directive     | Use when                                  |
| ------------- | ------------- | ----------------------------------------- |
| Round-robin   | *(default)*   | Backends are equal                        |
| Least conn.   | `least_conn`  | Requests vary in duration                 |
| IP hash       | `ip_hash`     | You need sticky sessions                  |

> For a dedicated TCP/HTTP load balancer with a stats dashboard, see
> [HAProxy](../haproxy.md).

---

## 9. Scenario: HTTPS with Redirect

Get a certificate with Certbot (see [Certbot](../security/certbot.md)):

```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d example.com -d www.example.com
```

The resulting hand-written equivalent:

```nginx
# HTTP → HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name example.com www.example.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;           # keep renewals working
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name example.com www.example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 1d;
    ssl_stapling on;
    ssl_stapling_verify on;

    add_header Strict-Transport-Security "max-age=63072000; includeSubDomains" always;

    root /var/www/example.com/html;
    index index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

Renewal is automatic; test it with:

```bash
sudo certbot renew --dry-run
```

---

## 10. Scenario: Multiple Sites and Subdomains

One file per site in `sites-available/`, each with its own `server_name`.

```nginx
# /etc/nginx/sites-available/blog.example.com
server {
    listen 80;
    server_name blog.example.com;
    root /var/www/blog;
    index index.html;
}
```

Catch every unmatched host and reject it (stops random domains resolving to your box):

```nginx
server {
    listen 80 default_server;
    server_name _;
    return 444;                          # close the connection with no response
}
```

Redirect `www` to the apex domain:

```nginx
server {
    listen 80;
    server_name www.example.com;
    return 301 http://example.com$request_uri;
}
```

---

## 11. Compression and Caching

In `/etc/nginx/nginx.conf` inside the `http` block:

```nginx
gzip on;
gzip_vary on;
gzip_min_length 1024;
gzip_comp_level 6;
gzip_proxied any;
gzip_types
    text/plain text/css text/xml application/json
    application/javascript application/xml+rss
    image/svg+xml application/wasm;
```

Proxy response cache:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=app_cache:10m
                 max_size=1g inactive=60m use_temp_path=off;

server {
    location / {
        proxy_cache app_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout updating http_502 http_503;
        add_header X-Cache-Status $upstream_cache_status;

        proxy_pass http://127.0.0.1:3000;
    }
}
```

Clear the cache:

```bash
sudo rm -rf /var/cache/nginx/*
sudo systemctl reload nginx
```

---

## 12. Security Hardening

Hide the version and set standard headers:

```nginx
server_tokens off;

add_header X-Frame-Options           "SAMEORIGIN"        always;
add_header X-Content-Type-Options    "nosniff"           always;
add_header Referrer-Policy           "strict-origin-when-cross-origin" always;
add_header Permissions-Policy        "geolocation=(), microphone=()"   always;
```

Rate limiting (in `http`, then applied in a `location`):

```nginx
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_conn_zone $binary_remote_addr zone=conn_limit:10m;

server {
    location /api/ {
        limit_req  zone=api_limit burst=20 nodelay;
        limit_conn conn_limit 10;
        proxy_pass http://127.0.0.1:3000;
    }
}
```

Block or allow by IP, and password-protect a path:

```nginx
location /admin/ {
    allow 203.0.113.0/24;
    deny  all;

    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
}
```

```bash
sudo apt install -y apache2-utils
sudo htpasswd -c /etc/nginx/.htpasswd admin
```

Body-size and timeout limits:

```nginx
client_max_body_size 16M;
client_body_timeout  12s;
client_header_timeout 12s;
send_timeout          10s;
```

---

## 13. Logs

```bash
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/example.com.error.log
```

Custom log format with upstream timing:

```nginx
log_format timed '$remote_addr - $remote_user [$time_local] "$request" '
                 '$status $body_bytes_sent "$http_referer" "$http_user_agent" '
                 'rt=$request_time urt=$upstream_response_time';

access_log /var/log/nginx/access.log timed;
```

Quick analysis:

```bash
# Top 10 IPs
sudo awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head
# Count by status code
sudo awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn
# Slowest requests (with the 'timed' format above)
sudo awk '{print $NF, $7}' /var/log/nginx/access.log | sort -rn | head
```

---

## 14. Troubleshooting

| Symptom | Likely cause | Check |
| ------- | ------------ | ----- |
| `502 Bad Gateway` | Backend down or wrong socket/port | `curl 127.0.0.1:3000`, `systemctl status php8.4-fpm` |
| `504 Gateway Timeout` | Backend too slow | Raise `proxy_read_timeout` |
| `403 Forbidden` | Permissions or missing index | `ls -la /var/www/...`, `namei -l /var/www/app/public` |
| `404` on SPA routes | No `try_files` fallback | See [section 7](#7-scenario-spa-react-vue-angular) |
| Config change ignored | Wrong site enabled, or not reloaded | `sudo nginx -T \| grep server_name` |
| Won't start | Port already bound | `sudo ss -tlnp \| grep :80` |

```bash
sudo nginx -t                                  # syntax
sudo journalctl -u nginx -n 50 --no-pager      # startup failures
sudo ss -tlnp | grep nginx                     # what it's listening on
curl -I -H "Host: example.com" http://127.0.0.1   # test a vhost without DNS
sudo nginx -T | grep -A5 "server_name example.com"
```

> ⚠️ SELinux on RHEL blocks outbound proxy connections by default:
> `sudo setsebool -P httpd_can_network_connect 1`.

---

## Summary

| Task | Command |
| ---- | ------- |
| Test config | `sudo nginx -t` |
| Graceful reload | `sudo systemctl reload nginx` |
| Enable a site | `sudo ln -s /etc/nginx/sites-available/x /etc/nginx/sites-enabled/` |
| Dump effective config | `sudo nginx -T` |
| Issue a certificate | `sudo certbot --nginx -d example.com` |
| Watch errors | `sudo tail -f /var/log/nginx/error.log` |
| Check listeners | `sudo ss -tlnp \| grep nginx` |

| Scenario | Key directive |
| -------- | ------------- |
| Static site | `try_files $uri $uri/ =404;` |
| PHP app | `fastcgi_pass unix:/run/php/php8.4-fpm.sock;` |
| Reverse proxy | `proxy_pass http://127.0.0.1:3000;` |
| SPA | `try_files $uri $uri/ /index.html;` |
| Load balance | `upstream backend { ... }` |
| Force HTTPS | `return 301 https://$host$request_uri;` |

---

## Done ✅

NGINX is installed, serving one or more sites, and you have a copy-ready block for each
common scenario. Next: [Apache](./apache.md) for the same patterns in Apache syntax, or
[Certbot](../security/certbot.md) to automate certificates.
