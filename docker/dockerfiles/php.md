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

- Uses PHP 8.1 FPM as runtime.
- Installs Git and unzip for Composer workflows.
- Installs production Composer dependencies (`--no-dev`).
- Exposes FPM on port `9000`.

## Required Files In Build Context

- `composer.json`
- `composer.lock` (recommended)
- PHP application source

## Build

```bash
docker build -t php-app -f docker/php/Dockerfile .
```

## Run

```bash
docker run --rm -p 9000:9000 php-app
```

## Note

- This image runs `php-fpm` only. Use Nginx/Apache as a separate web server.
