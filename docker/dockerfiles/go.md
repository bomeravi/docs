# Go Dockerfile

Source: `docker/go/Dockerfile`

## Dockerfile

```dockerfile
FROM golang:1.20-alpine AS build
WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o /app/main ./...

FROM alpine:3.18
RUN addgroup -S app && adduser -S -G app app
COPY --from=build /app/main /usr/local/bin/app
USER app
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/app"]
```

## What It Does

- Builds a static Go binary in a builder stage.
- Uses a minimal runtime image (`alpine`).
- Runs the app as non-root user.

## Required Files In Build Context

- `go.mod`
- `go.sum`
- Go source code with a runnable main package

## Docker Compose Example

```yaml
version: '3.8'
services:
  app:
    build:
      context: .
      dockerfile: docker/go/Dockerfile
    container_name: go-app
    env_file:
      - .env
    ports:
      - "8080:8080"
    restart: unless-stopped
```

## Other Files You Need

- `.env` (for example: `PORT`, `APP_ENV`, DB/redis URLs if your app uses them)
- `.dockerignore`
- Config files loaded by your Go app at runtime

## Build (Docker)

```bash
docker build -t go-app -f docker/go/Dockerfile .
```

## Run (Docker)

```bash
docker run --rm -p 8080:8080 go-app
```

## Run (Docker Compose)

```bash
docker compose up --build -d
```
