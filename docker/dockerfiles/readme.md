# Dockerfile Templates

This folder documents the Dockerfile templates available under `docker/<stack>/Dockerfile`.

## Available Dockerfiles

- [Django](./django.md)
- [Go](./go.md)
- [Java Microservice](./java-microservice.md)
- [Laravel](./laravel.md)
- [PHP](./php.md)
- [Python](./python.md)
- [React](./react.md)
- [WordPress](./wordpress.md)

## Notes

- These Dockerfiles are templates. Build context must include your application source files.
- If you build from repository root, use `-f docker/<stack>/Dockerfile`.
- For production deployments, pin image versions and scan images before release.
