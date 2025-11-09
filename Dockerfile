FROM node:16-alpine AS frontend-builder
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci && npm cache clean --force
COPY frontend/ ./
RUN npm run build

FROM node:16-alpine AS backend-builder
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY backend/ ./

FROM node:16-alpine AS runtime
WORKDIR /app
RUN adduser -D -u 1001 appuser && \
    chown -R appuser:appuser /app
COPY --from=backend-builder /app/node_modules ./node_modules
COPY --from=backend-builder /app/package*.json ./
COPY --from=backend-builder /app/ ./
COPY --from=frontend-builder /app/frontend/dist ./public
USER appuser
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s CMD node -e "require('http').get('http://localhost:3000/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
CMD ["npm", "start"]