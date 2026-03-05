# PHP Dockerfile

Source: `docker/php/Dockerfile`

## Dockerfile

```dockerfile
FROM php:8.1-fpm
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y git unzip && rm -rf /var/lib/apt/lists/*
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . /var/www/html
RUN composer install --no-dev --no-interaction --optimize-autoloader
CMD ["php-fpm"]
EXPOSE 9000
```

## What It Does

- Uses PHP 8.1 FPM runtime.
- Installs Composer and production dependencies.
- Exposes FPM on port `9000`.

## Required Files In Build Context

- `composer.json`
- `composer.lock` (recommended)
- PHP source code

## Docker Compose Example

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: docker/php/Dockerfile
    container_name: php-fpm-app
    env_file:
      - .env
    volumes:
      - .:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  web:
    image: nginx:alpine
    container_name: php-nginx
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html
      - ./docker/php/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    restart: unless-stopped

  db:
    image: mysql:8.0
    container_name: php-db
    environment:
      - MYSQL_DATABASE=appdb
      - MYSQL_USER=app
      - MYSQL_PASSWORD=password
      - MYSQL_ROOT_PASSWORD=rootpassword
    volumes:
      - mysql_data:/var/lib/mysql
    restart: unless-stopped

volumes:
  mysql_data:
```

## Other Files You Need

- `.env` with DB and app settings
- `docker/php/nginx.conf`
- Public entry file (for example `public/index.php`)

## Build (Docker)

```bash
docker build -t php-app -f docker/php/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 9000:9000 php-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
