# Python Dockerfile

Source: `docker/python/Dockerfile`

## Dockerfile

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["python","-m","http.server","8000"]
EXPOSE 8000
```

## What It Does

- Uses Python 3.11 slim image.
- Installs dependencies from `requirements.txt`.
- Starts a simple HTTP server on port `8000`.

## Required Files In Build Context

- `requirements.txt`
- Python project source files

## Docker Compose Example

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: docker/python/Dockerfile
    container_name: python-app
    env_file:
      - .env
    ports:
      - "8000:8000"
    volumes:
      - .:/app
    restart: unless-stopped
```

## Other Files You Need

- `.env` if your app uses environment-based config
- Entry module/script for your app
- `.dockerignore`

## Build (Docker)

```bash
docker build -t python-app -f docker/python/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 8000:8000 python-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
