FROM nginx:alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

# Copy frontend files
COPY index.html /usr/share/nginx/html/
COPY env-config.html /usr/share/nginx/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# Set default environment variable
ENV API_BASE_URL=http://localhost:8000

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
