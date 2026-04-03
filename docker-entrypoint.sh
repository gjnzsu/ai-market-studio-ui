#!/bin/sh

# Replace environment variables in env-config.js
envsubst '${API_BASE_URL}' < /usr/share/nginx/html/env-config.js > /usr/share/nginx/html/env-config.js.tmp
mv /usr/share/nginx/html/env-config.js.tmp /usr/share/nginx/html/env-config.js

# Start nginx
exec nginx -g 'daemon off;'
