# Jenkins Production Setup Guide (Ubuntu 24.04)

This guide configures Jenkins securely behind Apache2 with HTTPS,
firewall, and hardened settings.

------------------------------------------------------------------------

# 1. Install Jenkins (LTS)

Use the main installation guide before following this Apache production setup:

- [Jenkins installation guide](./readme.md) - follow **Installation (Ubuntu / Debian)**.
- [Server setup guide](./server-setup.md) - complete the first login and initial Jenkins web setup.

After Jenkins is installed and accessible, continue with the steps below.

------------------------------------------------------------------------

# 2. System Preparation

## Update System

``` bash
sudo apt update && sudo apt upgrade -y
```

## Install Required Packages
Not to use
``` bash
sudo apt install -y apache2 ufw fail2ban curl wget
```

------------------------------------------------------------------------

# 3. Restrict Jenkins to Localhost Only

Edit:

``` bash
sudo nano /etc/default/jenkins
```

Ensure:

    JENKINS_ARGS="--httpPort=8080 --httpListenAddress=127.0.0.1"

Restart:

``` bash
sudo systemctl restart jenkins
```

Verify:

``` bash
ss -lntp | grep 8080
```

Should bind only to 127.0.0.1.

------------------------------------------------------------------------

# 4. Configure Firewall (UFW)

``` bash
sudo ufw allow OpenSSH
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
sudo ufw status
```

DO NOT expose 8080 publicly.

------------------------------------------------------------------------

# 5. Enable Apache Required Modules

``` bash
sudo a2enmod proxy proxy_http proxy_wstunnel headers rewrite ssl
sudo systemctl restart apache2
```

------------------------------------------------------------------------

# 6. Apache Production VHost (HTTPS + Redirect)

Create:

``` bash
sudo nano /etc/apache2/sites-available/jenkins.digi.saroj.name.np.conf
```

Paste:

``` apache

<VirtualHost *:80>
    ServerName jenkins.digi.saroj.name.np

    ProxyPreserveHost On
    AllowEncodedSlashes NoDecode

    # --- Forwarded headers for Jenkins ---
    RequestHeader set X-Forwarded-Host "%{HTTP_HOST}s"
    RequestHeader set X-Forwarded-Port "80"
    RequestHeader set X-Forwarded-Proto "http"

    # Reverse proxy
    ProxyPass        /  http://127.0.0.1:8080/ nocanon
    ProxyPassReverse /  http://127.0.0.1:8080/

    # WebSocket support
    ProxyPass        /ws/  ws://127.0.0.1:8080/ws/ nocanon
    ProxyPassReverse /ws/  ws://127.0.0.1:8080/ws/

    ErrorLog ${APACHE_LOG_DIR}/jenkins_error.log
    CustomLog ${APACHE_LOG_DIR}/jenkins_access.log combined
</VirtualHost>
```


This is final output that we create later.

``` apache
<VirtualHost *:80>
    ServerName jenkins.digi.saroj.name.np
    RewriteEngine On
    RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]
</VirtualHost>

<VirtualHost *:443>
    ServerName jenkins.digi.saroj.name.np

    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/jenkins.digi.saroj.name.np/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/jenkins.digi.saroj.name.np/privkey.pem

    SSLProtocol all -SSLv3 -TLSv1 -TLSv1.1
    SSLCipherSuite HIGH:!aNULL:!MD5

    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    Header always set X-XSS-Protection "1; mode=block"

    ProxyPreserveHost On
    AllowEncodedSlashes NoDecode

    RequestHeader set X-Forwarded-Host "%{Host}i"
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Forwarded-Proto "https"

    ProxyPass        /  http://127.0.0.1:8080/ nocanon
    ProxyPassReverse /  http://127.0.0.1:8080/

    ProxyPass        /ws/  ws://127.0.0.1:8080/ws/ nocanon
    ProxyPassReverse /ws/  ws://127.0.0.1:8080/ws/

    ErrorLog ${APACHE_LOG_DIR}/jenkins_error.log
    CustomLog ${APACHE_LOG_DIR}/jenkins_access.log combined
</VirtualHost>
```

Enable site:

``` bash
sudo a2ensite jenkins.conf
sudo apache2ctl configtest
sudo systemctl reload apache2
```

------------------------------------------------------------------------

# 7. Install SSL (Let's Encrypt)

``` bash
sudo apt install certbot python3-certbot-apache
sudo certbot --apache -d jenkins.digi.saroj.name.np
```

Verify certificate:

``` bash
sudo certbot certificates
curl -I https://jenkins.digi.saroj.name.np
```

Test auto-renew:

``` bash
sudo certbot renew --dry-run
```


Once ssl installed edit the host file to make some changes,

```bash
sudo nano /etc/apache2/sites-available/jenkins.digi.saroj.name.np-le-ssl.conf
```
make this changes, this is used to forwarded all headers, port = 443, proto = https

```bash
    # --- Forwarded headers for Jenkins ---
    RequestHeader set X-Forwarded-Host "%{HTTP_HOST}i"
    RequestHeader set X-Forwarded-Port "443"
    RequestHeader set X-Forwarded-Proto "https"
```

------------------------------------------------------------------------

# 8. Jenkins Configuration

Inside Jenkins:

Manage Jenkins → Configure System

Set:

    Jenkins URL:
    https://jenkins.digi.saroj.name.np/

------------------------------------------------------------------------

# 9. Fail2Ban Protection

``` bash
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

Optional custom jail for Apache login protection.

------------------------------------------------------------------------

# 10. Systemd Hardening (Optional)

Create override:

``` bash
sudo systemctl edit jenkins
```

Add:

    [Service]
    LimitNOFILE=65536

Reload:

``` bash
sudo systemctl daemon-reexec
sudo systemctl restart jenkins
```

------------------------------------------------------------------------

# 11. Monitoring & Logs

Apache logs:

``` bash
sudo tail -f /var/log/apache2/jenkins_error.log
```

Jenkins logs:

``` bash
sudo journalctl -u jenkins -f
```

------------------------------------------------------------------------

- [Server setup guide](./server-setup.md) - complete the first login and initial Jenkins web setup.

# Production Checklist

✔ Jenkins bound to localhost\
✔ 8080 not publicly exposed\
✔ Firewall enabled\
✔ HTTPS enforced\
✔ HSTS enabled\
✔ Fail2Ban active\
✔ Auto-renew SSL tested

------------------------------------------------------------------------

Jenkins production deployment complete.
