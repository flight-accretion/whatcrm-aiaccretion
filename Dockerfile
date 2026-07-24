# ---------- Stage 1: deps (build native modules like bcrypt) ----------
FROM node:20-bookworm-slim AS deps

WORKDIR /app

# build tools needed for bcrypt / wrtc native bindings if no prebuilt binary matches
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    make \
    g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# ---------- Stage 2: runtime ----------
FROM node:20-bookworm-slim AS runtime

WORKDIR /app

# ffmpeg-static needs libs at runtime on debian slim; wrtc/baileys need ca-certs for TLS
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/*

# non-root user
RUN groupadd -g 1001 nodejs && useradd -u 1001 -g nodejs -m appuser

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# uploads/sessions/media folders may be written at runtime
RUN mkdir -p /app/sessions /app/uploads && chown -R appuser:nodejs /app

USER appuser

EXPOSE 3010

CMD ["node", "server.js"]