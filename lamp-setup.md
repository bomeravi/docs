# LAMP Setup 

(Apache2 + MySQL + Multi-PHP, PHP 8.4 default)
This guide targets Ubuntu 22.04/24.04 and installs Apache2, MySQL, and multiple PHP versions with PHP 8.4 as the default for both CLI and Apache.

## 1) Base packages

```bash
sudo apt update
sudo apt install -y apache2 mysql-server software-properties-common ca-certificates curl
```

## 2) Enable PHP PPA (for multiple PHP versions)

```bash
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update
```

## 3) Install PHP 8.4 (default) + additional versions

Pick the versions you need. Example installs 8.4 + 8.3 + 8.2 and common extensions:

```bash
sudo apt install -y \
  php8.4 php8.4-fpm php8.4-cli php8.4-mysql php8.4-xml php8.4-mbstring php8.4-curl php8.4-zip php8.4-gd php8.4-bcmath php8.4-intl \
  php8.3 php8.3-fpm php8.3-cli php8.3-mysql php8.3-xml php8.3-mbstring php8.3-curl php8.3-zip php8.3-gd php8.3-bcmath php8.3-intl \
  php8.2 php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-mbstring php8.2-curl php8.2-zip php8.2-gd php8.2-bcmath php8.2-intl
```

## 4) Apache + PHP-FPM integration

Use PHP-FPM for per-site version control.

```bash
sudo a2enmod proxy_fcgi setenvif
sudo a2enconf php8.4-fpm
sudo a2disconf php8.3-fpm php8.2-fpm || true
sudo systemctl restart apache2
```

## 5) Set PHP 8.4 as the default CLI version

```bash
sudo update-alternatives --set php /usr/bin/php8.4
php -v
```

## 6) MySQL hardening and basics

```bash
sudo systemctl enable --now mysql
sudo mysql_secure_installation
```

Optional: create a database and user.

```sql
CREATE DATABASE app_db;
CREATE USER 'app_user'@'localhost' IDENTIFIED BY 'password12';
GRANT ALL PRIVILEGES ON app_db.* TO 'app_user'@'localhost';
FLUSH PRIVILEGES;
```

Run with:

```bash
sudo mysql
```

## 7) phpMyAdmin (optional)

```bash
sudo apt install -y phpmyadmin
```

When prompted:
- Choose `apache2`.
- Select `Yes` to configure the database with `dbconfig-common`.

Ensure the PHP version used by Apache matches your default (8.4 in this guide):

```bash
 
```

Access it at:

```
http://your-server-ip/phpmyadmin
```

## 7) Per-site PHP version (Apache vhost)

Create a vhost and point it to the PHP-FPM socket you want:

```apache
<VirtualHost *:80>
    ServerName example.local
    DocumentRoot /var/www/example/public

    <Directory /var/www/example/public>
        AllowOverride All
        Require all granted
    </Directory>

    <FilesMatch \.php$>
        SetHandler "proxy:unix:/run/php/php8.4-fpm.sock|fcgi://localhost"
    </FilesMatch>
</VirtualHost>
```

To use PHP 8.3 for this site instead, swap the socket to:

```
/run/php/php8.3-fpm.sock
```

Then reload:

```bash
sudo systemctl reload apache2
```

## 8) Verify

```bash
apache2 -v
php -v
systemctl status apache2 mysql php8.4-fpm --no-pager
```

## Notes

- For production, lock down firewalls, enable HTTPS (Let’s Encrypt), and tune MySQL/PHP settings for your workload.
- If you want Apache to use `libapache2-mod-php` instead of PHP-FPM, install `libapache2-mod-php8.4` and disable FPM, but you lose per-site versioning.
