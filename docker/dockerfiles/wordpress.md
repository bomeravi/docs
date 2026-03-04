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

- Starts from official WordPress Apache image.
- Copies project files into WordPress web root.
- Exposes HTTP on port `80`.

## Required Files In Build Context

- WordPress content/customizations to copy into `/var/www/html`

## Build

```bash
docker build -t wordpress-app -f docker/wordpress/Dockerfile .
```

## Run

```bash
docker run --rm -p 8080:80 wordpress-app
```
