# Apache HTTP Server

Install, configure, and operate Apache (`apache2` / `httpd`) on Ubuntu, RHEL, and macOS —
with ready-to-copy virtual hosts for static hosting, PHP sites, reverse proxying, SPAs,
load balancing, HTTPS, and WebSockets.

> Apache is a process/thread-based web server built around **modules**. Almost every
> feature — proxying, SSL, rewrites, compression — is a module you enable with `a2enmod`.

---

## 1. Installation

### Ubuntu / Debian

```bash
sudo apt update
sudo apt install -y apache2
sudo systemctl enable --now apache2
```

### RHEL / CentOS / Rocky

```bash
sudo dnf install -y httpd
sudo systemctl enable --now httpd
```

> On RHEL the service, binary, and config dir are all `httpd`, not `apache2`.
> Replace the names throughout this page.

### macOS

```bash
brew install httpd
brew services start httpd
```

### Verify

```bash
apache2 -v
systemctl status apache2 --no-pager
curl -I http://localhost
```

Expected:

```text
HTTP/1.1 200 OK
Server: Apache/2.4.58 (Ubuntu)
```

> ⚠️ Port 80 conflicts with NGINX. If NGINX is running:
> `sudo systemctl disable --now nginx` first.

---

## 2. Config File Layout

| Path | Purpose |
| ---- | ------- |
| `/etc/apache2/apache2.conf` | Main config |
| `/etc/apache2/sites-available/` | All vhost files |
| `/etc/apache2/sites-enabled/` | Symlinks to active vhosts |
| `/etc/apache2/mods-available/` | All installed modules |
| `/etc/apache2/mods-enabled/` | Symlinks to active modules |
| `/etc/apache2/conf-available/` | Global config snippets |
| `/etc/apache2/ports.conf` | Which ports to `Listen` on |
| `/var/www/html/` | Default document root |
| `/var/log/apache2/` | `access.log` and `error.log` |

> Vhost files **must** end in `.conf` to be picked up by `a2ensite`.

---

## 3. Modules, Sites, and Service Commands

### Modules

```bash
sudo a2enmod rewrite headers ssl deflate expires
sudo a2dismod status
apache2ctl -M                          # list loaded modules
sudo systemctl restart apache2
```

Commonly needed modules:

| Module | Enables |
| ------ | ------- |
| `rewrite` | `RewriteRule`, pretty URLs, redirects |
| `ssl` | HTTPS / `SSLEngine` |
| `proxy`, `proxy_http` | Reverse proxying |
| `proxy_wstunnel` | WebSockets |
| `proxy_balancer`, `lbmethod_byrequests` | Load balancing |
| `proxy_fcgi`, `setenvif` | PHP-FPM |
| `headers` | `Header set ...` |
| `deflate` | gzip compression |
| `expires` | Cache-Control on static assets |

### Sites

```bash
sudo a2ensite example.com.conf
sudo a2dissite 000-default.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

### Service

```bash
sudo systemctl start apache2
sudo systemctl stop apache2
sudo systemctl restart apache2
sudo systemctl reload apache2          # graceful
sudo systemctl status apache2 --no-pager
```

Always test before reloading:

```bash
sudo apache2ctl configtest
sudo apachectl -S                      # dump the parsed vhost map
```

Expected:

```text
Syntax OK
```

---

## 4. Scenario: Static Website Hosting

```bash
sudo mkdir -p /var/www/example.com/html
sudo chown -R $USER:$USER /var/www/example.com/html
echo "<h1>example.com works</h1>" > /var/www/example.com/html/index.html
```

`/etc/apache2/sites-available/example.com.conf`:

```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com/html

    <Directory /var/www/example.com/html>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    # Cache static assets
    <IfModule mod_expires.c>
        ExpiresActive On
        ExpiresByType image/jpeg "access plus 1 year"
        ExpiresByType image/png  "access plus 1 year"
        ExpiresByType text/css   "access plus 1 year"
        ExpiresByType application/javascript "access plus 1 year"
    </IfModule>

    ErrorLog  ${APACHE_LOG_DIR}/example.com_error.log
    CustomLog ${APACHE_LOG_DIR}/example.com_access.log combined
</VirtualHost>
```

Enable it:

```bash
sudo a2ensite example.com.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

> `Options -Indexes` stops Apache listing directory contents when there is no
> `index.html` — leave it off in production.

---

## 5. Scenario: PHP Site (PHP-FPM)

Per-site PHP versions require PHP-FPM rather than `mod_php`.
See [LAMP Setup](../lamp-setup.md) for the full multi-version install.

```bash
sudo apt install -y php8.4-fpm
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.4-fpm
sudo systemctl restart apache2
```

`/etc/apache2/sites-available/app.example.com.conf`:

```apache
<VirtualHost *:80>
    ServerName app.example.com
    DocumentRoot /var/www/app/public     # Laravel: /public, WordPress: site root

    <Directory /var/www/app/public>
        Options -Indexes +FollowSymLinks
        AllowOverride All                # needed for .htaccess rewrites
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>

    # Block hidden files (.env, .git)
    <FilesMatch "^\.">
        Require all denied
    </FilesMatch>

    ErrorLog  ${APACHE_LOG_DIR}/app_error.log
    CustomLog ${APACHE_LOG_DIR}/app_access.log combined
</VirtualHost>
```

Fix ownership:

```bash
sudo chown -R www-data:www-data /var/www/app
sudo find /var/www/app -type d -exec chmod 755 {} \;
sudo find /var/www/app -type f -exec chmod 644 {} \;
```

Laravel `.htaccess` front-controller rewrite (already shipped in `public/`):

```apache
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>
```

> Swap the socket to `/run/php/php8.3-fpm.sock` to pin this site to another PHP version.

---

## 6. Scenario: Reverse Proxy

```bash
sudo a2enmod proxy proxy_http headers
sudo systemctl restart apache2
```

```apache
<VirtualHost *:80>
    ServerName api.example.com

    ProxyPreserveHost On
    ProxyRequests Off                    # never act as a forward proxy

    ProxyPass        /  http://127.0.0.1:3000/
    ProxyPassReverse /  http://127.0.0.1:3000/

    RequestHeader set X-Forwarded-Proto "http"
    RequestHeader set X-Forwarded-Port  "80"

    ProxyTimeout 60

    ErrorLog  ${APACHE_LOG_DIR}/api_error.log
    CustomLog ${APACHE_LOG_DIR}/api_access.log combined
</VirtualHost>
```

> ⚠️ `ProxyRequests Off` is essential. Leaving it on turns your server into an open
> forward proxy that anyone can relay traffic through.

### Exclude a path from the proxy

```apache
ProxyPass        /static/  !
Alias            /static/  /var/www/app/static/
ProxyPass        /         http://127.0.0.1:3000/
ProxyPassReverse /         http://127.0.0.1:3000/
```

### WebSockets

```bash
sudo a2enmod proxy_wstunnel
```

```apache
ProxyPass        /ws/  ws://127.0.0.1:3000/ws/
ProxyPassReverse /ws/  ws://127.0.0.1:3000/ws/
```

Upgrade-aware routing for apps that share one path:

```apache
RewriteEngine On
RewriteCond %{HTTP:Upgrade} =websocket [NC]
RewriteRule ^/?(.*) ws://127.0.0.1:3000/$1 [P,L]
RewriteCond %{HTTP:Upgrade} !=websocket [NC]
RewriteRule ^/?(.*) http://127.0.0.1:3000/$1 [P,L]
```

> A worked production example (Jenkins behind Apache with HTTPS) lives in
> [Jenkins Apache Setup](../jenkins/apache-setup.md).

---

## 7. Scenario: SPA (React, Vue, Angular)

```apache
<VirtualHost *:80>
    ServerName app.example.com
    DocumentRoot /var/www/react-app/dist

    <Directory /var/www/react-app/dist>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted

        # SPA fallback: unknown paths → index.html
        RewriteEngine On
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule ^ index.html [L]
    </Directory>

    # Never cache the entry point
    <Files "index.html">
        Header set Cache-Control "no-cache, must-revalidate"
    </Files>

    ErrorLog  ${APACHE_LOG_DIR}/spa_error.log
    CustomLog ${APACHE_LOG_DIR}/spa_access.log combined
</VirtualHost>
```

Requires `mod_rewrite` and `mod_headers`:

```bash
sudo a2enmod rewrite headers && sudo systemctl restart apache2
```

---

## 8. Scenario: Load Balancing

```bash
sudo a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
sudo systemctl restart apache2
```

```apache
<VirtualHost *:80>
    ServerName app.example.com

    <Proxy balancer://appcluster>
        BalancerMember http://10.0.0.11:8080 loadfactor=3
        BalancerMember http://10.0.0.12:8080
        BalancerMember http://10.0.0.13:8080 status=+H    # hot standby

        ProxySet lbmethod=byrequests
        ProxySet stickysession=JSESSIONID
    </Proxy>

    ProxyPreserveHost On
    ProxyPass        /balancer-manager !
    ProxyPass        /  balancer://appcluster/
    ProxyPassReverse /  balancer://appcluster/

    <Location /balancer-manager>
        SetHandler balancer-manager
        Require ip 127.0.0.1
    </Location>
</VirtualHost>
```

| `lbmethod` | Balances by |
| ---------- | ----------- |
| `byrequests` | Request count (default) |
| `bytraffic` | Bytes transferred |
| `bybusyness` | Active request count |

> The `balancer-manager` UI at `http://localhost/balancer-manager` lets you drain a
> member live. Keep it restricted to localhost.

---

## 9. Scenario: HTTPS with Redirect

```bash
sudo apt install -y certbot python3-certbot-apache
sudo certbot --apache -d example.com -d www.example.com
```

The hand-written equivalent:

```apache
<VirtualHost *:80>
    ServerName example.com
    ServerAlias www.example.com

    RewriteEngine On
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
    ServerName example.com
    ServerAlias www.example.com
    DocumentRoot /var/www/example.com/html

    SSLEngine on
    SSLCertificateFile    /etc/letsencrypt/live/example.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/example.com/privkey.pem

    SSLProtocol -all +TLSv1.2 +TLSv1.3
    SSLCipherSuite HIGH:!aNULL:!MD5
    SSLHonorCipherOrder off

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"

    <Directory /var/www/example.com/html>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog  ${APACHE_LOG_DIR}/example.com_ssl_error.log
    CustomLog ${APACHE_LOG_DIR}/example.com_ssl_access.log combined
</VirtualHost>
```

```bash
sudo a2enmod ssl
sudo a2ensite example.com.conf
sudo apache2ctl configtest && sudo systemctl reload apache2
sudo certbot renew --dry-run
```

> For local development certificates, see [Custom HTTPS](../security/custom-https.md).

---

## 10. Scenario: Multiple Sites and Subdomains

One `.conf` per site. The **first** matching vhost wins, and the first vhost overall is
the default for unmatched hosts — so define an explicit catch-all:

```apache
<VirtualHost *:80>
    ServerName catchall.invalid
    DocumentRoot /var/www/empty
    Redirect 404 /
</VirtualHost>
```

Redirect `www` to apex:

```apache
<VirtualHost *:80>
    ServerName www.example.com
    Redirect permanent / http://example.com/
</VirtualHost>
```

Check which vhost serves what:

```bash
sudo apachectl -S
```

---

## 11. Compression and Caching

```bash
sudo a2enmod deflate expires headers
```

```apache
<IfModule mod_deflate.c>
    AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css
    AddOutputFilterByType DEFLATE application/javascript application/json
    AddOutputFilterByType DEFLATE image/svg+xml
</IfModule>

<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresByType text/css                "access plus 1 year"
    ExpiresByType application/javascript  "access plus 1 year"
    ExpiresByType image/png               "access plus 1 year"
    ExpiresDefault                        "access plus 1 hour"
</IfModule>
```

---

## 12. Security Hardening

Hide version details in `/etc/apache2/conf-available/security.conf`:

```apache
ServerTokens Prod
ServerSignature Off
TraceEnable Off
```

Security headers:

```apache
Header always set X-Frame-Options        "SAMEORIGIN"
Header always set X-Content-Type-Options "nosniff"
Header always set Referrer-Policy        "strict-origin-when-cross-origin"
Header always unset X-Powered-By
```

Restrict by IP and add basic auth:

```apache
<Location /admin>
    Require ip 203.0.113.0/24

    AuthType Basic
    AuthName "Restricted"
    AuthUserFile /etc/apache2/.htpasswd
    Require valid-user
</Location>
```

```bash
sudo htpasswd -c /etc/apache2/.htpasswd admin
```

Limits and timeouts in `apache2.conf`:

```apache
Timeout 60
KeepAlive On
KeepAliveTimeout 5
MaxKeepAliveRequests 100
LimitRequestBody 16777216
```

> ⚠️ `AllowOverride All` lets any `.htaccess` in the tree change behaviour and costs a
> filesystem lookup per request. Use `AllowOverride None` and move rules into the vhost
> unless the app requires `.htaccess` (WordPress, Laravel).

---

## 13. Logs

```bash
sudo tail -f /var/log/apache2/error.log
sudo tail -f /var/log/apache2/access.log
sudo tail -f /var/log/apache2/example.com_error.log
```

Raise verbosity while debugging:

```apache
LogLevel warn
# LogLevel debug
# LogLevel proxy:trace5      # per-module, for proxy problems
```

Quick analysis:

```bash
sudo awk '{print $1}' /var/log/apache2/access.log | sort | uniq -c | sort -rn | head
sudo awk '{print $9}' /var/log/apache2/access.log | sort | uniq -c | sort -rn
sudo grep -c "AH00124" /var/log/apache2/error.log   # rewrite loops
```

---

## 14. Troubleshooting

| Symptom | Likely cause | Check |
| ------- | ------------ | ----- |
| `503 Service Unavailable` | Backend down, or proxy module missing | `curl 127.0.0.1:3000`, `apache2ctl -M \| grep proxy` |
| `403 Forbidden` | Missing `Require all granted` or bad perms | `namei -l /var/www/app/public` |
| `500` on a PHP site | FPM socket wrong or down | `systemctl status php8.4-fpm` |
| `.htaccess` ignored | `AllowOverride None` | Set `AllowOverride All` in `<Directory>` |
| Rewrites do nothing | `mod_rewrite` not enabled | `sudo a2enmod rewrite` |
| Wrong site served | Vhost order / `ServerName` typo | `sudo apachectl -S` |
| Won't start | Port already bound | `sudo ss -tlnp \| grep :80` |

```bash
sudo apache2ctl configtest
sudo apachectl -S
sudo apache2ctl -M
sudo journalctl -u apache2 -n 50 --no-pager
curl -I -H "Host: example.com" http://127.0.0.1
```

> ⚠️ SELinux on RHEL blocks proxying by default:
> `sudo setsebool -P httpd_can_network_connect 1`.

---

## Summary

| Task | Command |
| ---- | ------- |
| Test config | `sudo apache2ctl configtest` |
| Show vhost map | `sudo apachectl -S` |
| List modules | `sudo apache2ctl -M` |
| Enable module | `sudo a2enmod rewrite` |
| Enable site | `sudo a2ensite example.com.conf` |
| Graceful reload | `sudo systemctl reload apache2` |
| Issue a certificate | `sudo certbot --apache -d example.com` |
| Watch errors | `sudo tail -f /var/log/apache2/error.log` |

| Scenario | Key directive |
| -------- | ------------- |
| Static site | `DocumentRoot` + `Require all granted` |
| PHP app | `SetHandler "proxy:unix:/run/php/php8.4-fpm.sock\|fcgi://localhost"` |
| Reverse proxy | `ProxyPass / http://127.0.0.1:3000/` |
| SPA | `RewriteRule ^ index.html [L]` |
| Load balance | `<Proxy balancer://appcluster>` |
| Force HTTPS | `RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]` |

---

## Done ✅

Apache is installed, serving one or more vhosts, and you have a copy-ready block for each
common scenario. Next: [NGINX](./nginx.md) for the same patterns in NGINX syntax, or
[LAMP Setup](../lamp-setup.md) for the full Apache + MySQL + multi-PHP stack.
