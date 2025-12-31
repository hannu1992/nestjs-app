# =========================
# 1) Build stage
# =========================
FROM node:22-alpine AS builder

WORKDIR /app

# Install deps first (better caching)
COPY package*.json ./
RUN npm ci

# Copy source & build
COPY . .
RUN npm run build

# =========================
# 2) Runtime stage
# =========================
FROM node:22-alpine

WORKDIR /app
ENV NODE_ENV=production

# Install minimal runtime deps (for HEALTHCHECK)
RUN apk add --no-cache wget

# Copy only what is needed to run
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package*.json ./

# Install production dependencies only
RUN npm ci --only=production

# Expose app port
EXPOSE 3000

# Docker-level health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start app
CMD ["node", "dist/main.js"]