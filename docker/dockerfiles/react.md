# React Dockerfile

Source: `docker/react/Dockerfile`

## Dockerfile

```dockerfile
# Build stage
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Production stage
FROM nginx:stable-alpine
COPY --from=build /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

## What It Does

- Uses multi-stage build to compile React assets.
- Serves static build output with Nginx.
- Exposes HTTP on port `80`.

## Required Files In Build Context

- `package.json`
- `package-lock.json` (or compatible lockfile)
- React source (`src/`, `public/`)

## Docker Compose Example

```yaml
version: '3.8'
services:
  frontend:
    build:
      context: .
      dockerfile: docker/react/Dockerfile
    container_name: react-frontend
    ports:
      - "3000:80"
    env_file:
      - .env
    restart: unless-stopped
```

## Other Files You Need

- `.env` for build-time values (for example `REACT_APP_API_URL`)
- Frontend routing fallback config if you serve SPA routes through Nginx
- `.dockerignore`

## Build (Docker)

```bash
docker build -t react-app -f docker/react/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 3000:80 react-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
