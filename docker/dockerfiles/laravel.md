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

- Builds a PHP-FPM 8.1 image for Laravel apps.
- Installs common system packages and PHP extensions for Laravel.
- Installs Composer dependencies.
- Exposes FPM on port `9000`.

## Required Files In Build Context

- `composer.json`
- `composer.lock` (recommended)
- Laravel application source

## Build

```bash
docker build -t laravel-app -f docker/laravel/Dockerfile .
```

## Run

```bash
docker run --rm -p 9000:9000 laravel-app
```

## Note

- This image runs `php-fpm` only. Pair it with Nginx/Apache for HTTP serving.
