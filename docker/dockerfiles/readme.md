# Dockerfile Templates

This folder documents the Dockerfile templates under `docker/<stack>/Dockerfile`, plus Docker Compose examples and required companion files.

## Available Guides

- [Django](./django.md)
- [Go](./go.md)
- [Java Microservice](./java-microservice.md)
- [Laravel](./laravel.md)
- [PHP](./php.md)
- [Python](./python.md)
- [React](./react.md)
- [WordPress](./wordpress.md)

## Shared Files You Usually Need

- `docker-compose.yml` (or `docker-compose.<stack>.yml`)
- `.env` for runtime variables and secrets
- `.dockerignore` to reduce build context size
- App-specific config files (for example `nginx.conf`, `wp-config.php`, framework env files)

## Common Compose Commands

```bash
# Start services

docker compose up --build

# Run in background

docker compose up -d --build

# Stop and remove containers

docker compose down

# View logs

docker compose logs -f
```

## Notes

- Compose examples in each page are templates; adjust ports, image tags, and env vars.
- Use named volumes for databases and uploads.
- Keep secrets out of Git by using `.env` and secret managers.
