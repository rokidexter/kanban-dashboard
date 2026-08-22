# Stage 1: Build the React/Vite application
FROM node:22-alpine AS builder

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy application source code
COPY . .

# Create production build
RUN npm run build


# Stage 2: Serve the production build with Nginx
FROM nginx:alpine

# Remove default Nginx configuration and web content
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf

# Copy production build
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Create directories required by Nginx
RUN mkdir -p /var/cache/nginx \
    /var/log/nginx \
    /var/run \
    && touch /var/run/nginx.pid \
    && chown -R nginx:nginx \
       /usr/share/nginx/html \
       /var/cache/nginx \
       /var/log/nginx \
       /var/run/nginx.pid

# Run as non-root user
USER nginx

# Application port
EXPOSE 80

# Container health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]