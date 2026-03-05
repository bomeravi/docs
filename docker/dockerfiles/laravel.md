# Laravel Dockerfile

Source: `docker/laravel/Dockerfile`

## Dockerfile

```dockerfile
FROM php:8.1-fpm
WORKDIR /var/www/html
RUN apt-get update && apt-get install -y libpng-dev libonig-dev libxml2-dev zip unzip git && rm -rf /var/lib/apt/lists/*
RUN docker-php-ext-install pdo pdo_mysql mbstring exif pcntl bcmath gd
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer
COPY . /var/www/html
RUN composer install --no-interaction --prefer-dist --optimize-autoloader
CMD ["php-fpm"]
EXPOSE 9000
```

## What It Does

- Builds a PHP-FPM image suitable for Laravel.
- Installs common Laravel PHP extensions.
- Installs Composer dependencies.
- Exposes FPM on `9000`.

## Required Files In Build Context

- `composer.json`
- `composer.lock` (recommended)
- Laravel app source (`artisan`, `app/`, `config/`, `public/`, `routes/`)

## Docker Compose Example

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: docker/laravel/Dockerfile
    container_name: laravel-app
    working_dir: /var/www/html
    env_file:
      - .env
    volumes:
      - .:/var/www/html
    depends_on:
      - db
    restart: unless-stopped

  web:
    image: nginx:alpine
    container_name: laravel-nginx
    ports:
      - "8080:80"
    volumes:
      - .:/var/www/html
      - ./docker/laravel/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - app
    restart: unless-stopped

  db:
    image: mysql:8.0
    container_name: laravel-db
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

- `.env` (`APP_KEY`, `DB_HOST`, `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`)
- `docker/laravel/nginx.conf`
- Writable Laravel directories: `storage/`, `bootstrap/cache/`

## Build (Docker)

```bash
docker build -t laravel-app -f docker/laravel/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 9000:9000 laravel-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
