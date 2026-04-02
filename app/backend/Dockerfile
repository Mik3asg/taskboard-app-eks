# Single-stage Node.js image — production dependencies only
FROM node:20-alpine
# Upgrade all packages to pick up security patches
RUN apk upgrade --no-cache
WORKDIR /app

# Install prod dependencies (separate layer for Docker cache efficiency)
COPY app/backend/package*.json ./
RUN npm ci --omit=dev

# Copy application source
COPY app/backend/src/ src/

EXPOSE 8000
CMD ["node", "src/index.js"]
