# Node.js Dockerfile

Source: `docker/node/Dockerfile`

This template runs a production Node.js HTTP application as the unprivileged
`node` user. It uses Node.js 24, which is the current LTS line; production
applications should stay on an actively supported LTS release and pin the image
to a tested version or digest during their release process.

It uses a multi-stage build so the final image contains application files and
locked production dependencies only. The npm download cache is retained by the
builder for faster rebuilds but is never copied into the runtime image.

## Dockerfile

```dockerfile
# syntax=docker/dockerfile:1

FROM node:24-alpine AS production-dependencies

ENV NODE_ENV=production

WORKDIR /app

# This layer is reused until the dependency manifests change.
COPY --chown=node:node package.json package-lock.json ./
USER node
RUN --mount=type=cache,target=/home/node/.npm,uid=1000,gid=1000 \
    npm ci --omit=dev

FROM node:24-alpine AS runtime

ENV NODE_ENV=production \
    PORT=3000

WORKDIR /app

# The final image receives production dependencies only, not the npm cache.
COPY --from=production-dependencies --chown=node:node /app/node_modules ./node_modules
COPY --chown=node:node package.json ./

# Keep common local and sensitive files out even if .dockerignore is incomplete.
COPY --chown=node:node \
    --exclude=.git \
    --exclude=.env \
    --exclude=.env.* \
    --exclude=node_modules \
    . .

USER node
EXPOSE 3000

CMD ["node", "server.js"]
```

## Assumptions

- The build context contains `package.json`, `package-lock.json`, and the
  application source.
- `server.js` starts the HTTP server and reads `PORT` (default `3000`). Change
  the final `CMD` for another entry point, for example
  `CMD ["node", "dist/server.js"]`.
- Production dependencies are accurately listed in `dependencies`; packages
  needed only to build or test belong in `devDependencies`.

`npm ci` intentionally requires a lock file and fails when it does not match
`package.json`. This makes builds repeatable and exposes an out-of-date lock
file early.

## Recommended `.dockerignore`

Create this file at the application repository root. It reduces the build
context sent to Docker and prevents local files from being copied into the
image. The Dockerfile also excludes the most sensitive/common large paths as a
second safeguard, but `.dockerignore` is still needed for an efficient build:

```gitignore
node_modules
npm-debug.log*
.git
.env
.env.*
coverage
```

Do not ignore compiled output such as `dist/` when the container needs it at
runtime.

## Build compatibility

The dependency cache mount and `COPY --exclude` options use the current
BuildKit Dockerfile syntax, enabled by the first line of the Dockerfile. Modern
Docker uses BuildKit by default. If a legacy builder cannot use this template,
upgrade Docker rather than removing the exclusions; otherwise local
`node_modules` or environment files can unnecessarily enter the build context.

## Build and run

From the application repository root:

```bash
docker build -t node-app -f docker/node/Dockerfile .
docker run --rm -p 3000:3000 --env-file .env node-app
```

Check the health endpoint when the application provides one:

```bash
curl -fsS http://localhost:3000/health
```

## Docker Compose example

```yaml
services:
  app:
    build:
      context: .
      dockerfile: docker/node/Dockerfile
    env_file:
      - .env
    ports:
      - "3000:3000"
    restart: unless-stopped
```

## TypeScript or build-step applications

This is a runtime-only template. If your Node application compiles TypeScript,
bundles code, or generates assets, use a separate build stage that runs
`npm ci` and the build command, then copy only the generated output and
production dependencies into the runtime image. Do not include development
tooling in the final image.

## Related

- [Node.js Releases](https://nodejs.org/en/about/previous-releases) — supported
  release lines.
- [Docker](../readme.md) — installation, commands, and Docker Compose.
- [Kubernetes Node Manifest](../../kubernetes/manifests/node/README.md) — Node
  workload deployment example.
