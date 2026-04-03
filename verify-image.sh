#!/bin/bash
# Docker Image Verification Script
# Verifies that the Docker image contains correct files before deployment

set -e

IMAGE="${1:-gcr.io/gen-lang-client-0896070179/ai-market-studio-ui:latest}"

echo "=========================================="
echo "Docker Image Verification"
echo "=========================================="
echo "Image: $IMAGE"
echo ""

# Test 1: Check if env-config.js exists
echo "Test 1: Checking if env-config.js exists..."
if docker run --rm $IMAGE sh -c "test -f /usr/share/nginx/html/env-config.js"; then
    echo "✓ env-config.js exists"
else
    echo "✗ env-config.js not found"
    exit 1
fi
echo ""

# Test 2: Check env-config.js content
echo "Test 2: Checking env-config.js content..."
CONTENT=$(docker run --rm $IMAGE cat /usr/share/nginx/html/env-config.js)

if echo "$CONTENT" | grep -q "window.ENV"; then
    echo "✓ Contains window.ENV"
else
    echo "✗ Missing window.ENV"
    exit 1
fi

if echo "$CONTENT" | grep -q "API_BASE_URL"; then
    echo "✓ Contains API_BASE_URL"
else
    echo "✗ Missing API_BASE_URL"
    exit 1
fi

if echo "$CONTENT" | grep -q '\${API_BASE_URL}'; then
    echo "✓ Contains placeholder \${API_BASE_URL}"
else
    echo "✗ Missing placeholder \${API_BASE_URL}"
    exit 1
fi
echo ""

# Test 3: Check if index.html references env-config.js
echo "Test 3: Checking index.html references..."
INDEX_CONTENT=$(docker run --rm $IMAGE cat /usr/share/nginx/html/index.html)

if echo "$INDEX_CONTENT" | grep -q 'src="env-config.js"'; then
    echo "✓ index.html references env-config.js"
else
    echo "✗ index.html does not reference env-config.js"
    exit 1
fi
echo ""

# Test 4: Check nginx.conf has cache-control for config file
echo "Test 4: Checking nginx.conf cache-control..."
NGINX_CONF=$(docker run --rm $IMAGE cat /etc/nginx/conf.d/default.conf)

if echo "$NGINX_CONF" | grep -q "location = /env-config.js"; then
    echo "✓ nginx.conf has specific location for env-config.js"
else
    echo "⚠ Warning: nginx.conf may not have cache-control for env-config.js"
fi

if echo "$NGINX_CONF" | grep -q "no-cache"; then
    echo "✓ nginx.conf has no-cache directive"
else
    echo "⚠ Warning: nginx.conf may not prevent caching"
fi
echo ""

# Test 5: Check docker-entrypoint.sh references env-config.js
echo "Test 5: Checking docker-entrypoint.sh..."
ENTRYPOINT=$(docker run --rm $IMAGE cat /docker-entrypoint.sh)

if echo "$ENTRYPOINT" | grep -q "env-config.js"; then
    echo "✓ docker-entrypoint.sh references env-config.js"
else
    echo "✗ docker-entrypoint.sh does not reference env-config.js"
    exit 1
fi
echo ""

echo "=========================================="
echo "✓ All Verification Tests Passed!"
echo "=========================================="
echo ""
echo "Image is ready for deployment:"
echo "  docker push $IMAGE"
echo "  kubectl rollout restart deployment/ai-market-studio-ui"
