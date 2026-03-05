# WordPress Dockerfile

Source: `docker/wordpress/Dockerfile`

## Dockerfile

```dockerfile
FROM wordpress:php8.0-apache
# Use official WordPress image; copy custom themes/plugins here if needed
COPY . /var/www/html
EXPOSE 80
```

## What It Does

- Uses official WordPress Apache image.
- Copies WordPress files/customizations to `/var/www/html`.
- Exposes HTTP on port `80`.

## Required Files In Build Context

- WordPress content/customizations (themes, plugins, uploads if required)
- Optional custom `wp-config.php`

## Docker Compose Example

```yaml
version: '3.8'
services:
  wordpress:
    build:
      context: .
      dockerfile: docker/wordpress/Dockerfile
    container_name: wordpress
    ports:
      - "8080:80"
    environment:
      - WORDPRESS_DB_HOST=db:3306
      - WORDPRESS_DB_NAME=wordpress
      - WORDPRESS_DB_USER=wpuser
      - WORDPRESS_DB_PASSWORD=wppassword
    volumes:
      - wordpress_data:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: mysql:8.0
    container_name: wordpress-db
    environment:
      - MYSQL_DATABASE=wordpress
      - MYSQL_USER=wpuser
      - MYSQL_PASSWORD=wppassword
      - MYSQL_ROOT_PASSWORD=rootpassword
    volumes:
      - db_data:/var/lib/mysql
    restart: unless-stopped

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: phpmyadmin
    ports:
      - "8081:80"
    environment:
      - PMA_HOST=db
      - MYSQL_ROOT_PASSWORD=rootpassword
    depends_on:
      - db
    restart: unless-stopped

volumes:
  wordpress_data:
  db_data:
```

## Other Files You Need

- `.env` to keep DB credentials out of version control
- Optional `php.ini` for upload limits/timezone
- Persistent volumes for MySQL and WordPress files

## Build (Docker)

```bash
docker build -t wordpress-app -f docker/wordpress/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 8080:80 wordpress-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
