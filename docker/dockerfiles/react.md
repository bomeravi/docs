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

- Uses a multi-stage build to compile React assets with Node.
- Copies static build output into Nginx runtime image.
- Serves the app via Nginx on port `80`.

## Required Files In Build Context

- `package.json`
- `package-lock.json` (or compatible lockfile)
- React source files

## Build

```bash
docker build -t react-app -f docker/react/Dockerfile .
```

## Run

```bash
docker run --rm -p 8080:80 react-app
```
