#!/bin/sh

# Replace environment variables in env-config.html
envsubst '${API_BASE_URL}' < /usr/share/nginx/html/env-config.html > /usr/share/nginx/html/env-config.html.tmp
mv /usr/share/nginx/html/env-config.html.tmp /usr/share/nginx/html/env-config.html

# Start nginx
exec nginx -g 'daemon off;'
