# Stage 1: Build stage (Node Alpine)
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stage 2: Production runtime stage (Unprivileged Nginx Alpine)
FROM nginxinc/nginx-unprivileged:alpine-slim
WORKDIR /usr/share/nginx/html

# Copy compiled static assets from builder stage
COPY --from=builder /app/dist .

# Non-root unprivileged Nginx listens on 8080
EXPOSE 8080

# Reliable health check probe
HEALTHCHECK --interval=15s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O - http://127.0.0.1:8080/ > /dev/null || exit 1

CMD ["nginx", "-g", "daemon off;"]
