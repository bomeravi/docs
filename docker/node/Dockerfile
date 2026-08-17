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
