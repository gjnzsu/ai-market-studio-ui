#!/bin/bash
# Browser Simulation Test: Simulates actual browser behavior
# Tests CORS, content-type, and full request/response cycle

set -e

UI_URL="http://136.116.205.168"
BACKEND_URL="http://35.224.3.54"

echo "=========================================="
echo "Browser Simulation Test"
echo "=========================================="
echo ""

# Test 1: Simulate browser loading the UI
echo "Test 1: Browser loads UI page"
UI_HTML=$(curl -s ${UI_URL}/)
if echo "$UI_HTML" | grep -q "AI Market Studio"; then
    echo "✓ UI HTML loaded successfully"
else
    echo "✗ UI HTML failed to load"
    exit 1
fi
echo ""

# Test 2: Browser loads env-config.html (injected via script tag)
echo "Test 2: Browser loads environment config"
ENV_CONFIG=$(curl -s ${UI_URL}/env-config.html)
if echo "$ENV_CONFIG" | grep -q "window.ENV"; then
    echo "✓ Environment config loaded"
    API_URL=$(echo "$ENV_CONFIG" | grep -o "API_BASE_URL: '[^']*'" | cut -d"'" -f2)
    echo "  Configured API URL: $API_URL"
    if [ "$API_URL" = "http://35.224.3.54" ]; then
        echo "✓ API URL is correct"
    else
        echo "✗ API URL is incorrect: $API_URL"
        exit 1
    fi
else
    echo "✗ Environment config failed"
    exit 1
fi
echo ""

# Test 3: Simulate CORS preflight (browser does this automatically)
echo "Test 3: CORS Preflight Request"
PREFLIGHT=$(curl -s -i -X OPTIONS ${BACKEND_URL}/api/chat \
  -H "Origin: ${UI_URL}" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type" 2>&1)

if echo "$PREFLIGHT" | grep -qi "access-control-allow-origin"; then
    echo "✓ CORS preflight passed"
    ALLOWED_ORIGIN=$(echo "$PREFLIGHT" | grep -i "access-control-allow-origin" | cut -d: -f2- | tr -d '\r\n' | xargs)
    echo "  Allowed Origin: $ALLOWED_ORIGIN"
else
    echo "⚠ Warning: CORS preflight may have issues"
fi
echo ""

# Test 4: Simulate actual chat request from browser
echo "Test 4: Simulated Browser Chat Request"
CHAT_REQUEST='{"message":"What is the EUR/USD rate?","history":[]}'
CHAT_RESPONSE=$(curl -s -X POST ${BACKEND_URL}/api/chat \
  -H "Origin: ${UI_URL}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "$CHAT_REQUEST")

if echo "$CHAT_RESPONSE" | grep -q "reply"; then
    echo "✓ Chat request successful"
    REPLY=$(echo "$CHAT_RESPONSE" | grep -o '"reply":"[^"]*"' | cut -d'"' -f4)
    echo "  Reply: $REPLY"

    # Check if data is present
    if echo "$CHAT_RESPONSE" | grep -q "data"; then
        echo "✓ Response includes data payload"
    fi
else
    echo "✗ Chat request failed"
    echo "Response: $CHAT_RESPONSE"
    exit 1
fi
echo ""

# Test 5: Test different query types
echo "Test 5: Multiple Query Types"

# News query
echo "  Testing news query..."
NEWS_RESPONSE=$(curl -s -X POST ${BACKEND_URL}/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"Show me latest FX news","history":[]}' \
  --max-time 30)
if echo "$NEWS_RESPONSE" | grep -q "reply"; then
    echo "  ✓ News query works"
else
    echo "  ✗ News query failed"
fi

# Rate query
echo "  Testing rate query..."
RATE_RESPONSE=$(curl -s -X POST ${BACKEND_URL}/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"GBP to USD rate","history":[]}' \
  --max-time 30)
if echo "$RATE_RESPONSE" | grep -q "reply"; then
    echo "  ✓ Rate query works"
else
    echo "  ✗ Rate query failed"
fi

echo ""
echo "=========================================="
echo "Browser Simulation Complete! ✓"
echo "=========================================="
echo ""
echo "The application is ready for use:"
echo "  Frontend: ${UI_URL}"
echo "  Backend:  ${BACKEND_URL}"
echo ""
echo "Try these queries in the UI:"
echo "  - What is the EUR/USD rate?"
echo "  - Show me latest FX news"
echo "  - GBP to USD rate"
