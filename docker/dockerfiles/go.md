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

- Uses a multi-stage build for smaller runtime images.
- Compiles a static Go binary in the build stage.
- Runs as a non-root user in the final stage.
- Exposes port `8080`.

## Required Files In Build Context

- `go.mod`
- `go.sum`
- Go source files

## Build

```bash
docker build -t go-app -f docker/go/Dockerfile .
```

## Run

```bash
docker run --rm -p 8080:8080 go-app
```
