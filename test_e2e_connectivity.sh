#!/bin/bash
# E2E Test: Verify UI can connect to Backend API
# Tests the full flow from external browser perspective

set -e

UI_URL="http://136.116.205.168"
BACKEND_URL="http://35.224.3.54"

echo "=========================================="
echo "E2E Connectivity Test"
echo "=========================================="
echo ""

# Test 1: Backend API is accessible
echo "Test 1: Backend API Health Check"
echo "Testing: GET ${BACKEND_URL}/docs"
BACKEND_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${BACKEND_URL}/docs --max-time 10)
if [ "$BACKEND_STATUS" = "200" ]; then
    echo "✓ Backend API is accessible (HTTP $BACKEND_STATUS)"
else
    echo "✗ Backend API failed (HTTP $BACKEND_STATUS)"
    exit 1
fi
echo ""

# Test 2: UI is accessible
echo "Test 2: UI Health Check"
echo "Testing: GET ${UI_URL}/"
UI_STATUS=$(curl -s -o /dev/null -w "%{http_code}" ${UI_URL}/ --max-time 10)
if [ "$UI_STATUS" = "200" ]; then
    echo "✓ UI is accessible (HTTP $UI_STATUS)"
else
    echo "✗ UI failed (HTTP $UI_STATUS)"
    exit 1
fi
echo ""

# Test 3: UI has correct API configuration
echo "Test 3: UI API Configuration"
echo "Testing: env-config.html contains correct backend URL"
ENV_CONFIG=$(curl -s ${UI_URL}/env-config.html)
if echo "$ENV_CONFIG" | grep -q "http://35.224.3.54"; then
    echo "✓ UI configured with correct backend URL"
else
    echo "✗ UI has incorrect backend URL"
    echo "Expected: http://35.224.3.54"
    echo "Got: $ENV_CONFIG"
    exit 1
fi
echo ""

# Test 4: Backend chat endpoint is functional
echo "Test 4: Backend Chat Endpoint"
echo "Testing: POST ${BACKEND_URL}/api/chat"
CHAT_RESPONSE=$(curl -s -X POST ${BACKEND_URL}/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"What is the current EUR/USD rate?","history":[]}' \
  --max-time 30)

if echo "$CHAT_RESPONSE" | grep -q "reply"; then
    echo "✓ Backend chat endpoint is functional"
    REPLY=$(echo "$CHAT_RESPONSE" | grep -o '"reply":"[^"]*"' | head -c 80)
    echo "Response preview: $REPLY..."
else
    echo "✗ Backend chat endpoint failed"
    echo "Response: $CHAT_RESPONSE"
    exit 1
fi
echo ""

# Test 5: CORS headers check
echo "Test 5: CORS Configuration"
echo "Testing: OPTIONS ${BACKEND_URL}/api/chat"
CORS_HEADERS=$(curl -s -I -X OPTIONS ${BACKEND_URL}/api/chat \
  -H "Origin: ${UI_URL}" \
  -H "Access-Control-Request-Method: POST" \
  --max-time 10)

if echo "$CORS_HEADERS" | grep -qi "access-control-allow-origin"; then
    echo "✓ CORS headers present"
else
    echo "⚠ Warning: CORS headers may not be configured"
fi
echo ""

echo "=========================================="
echo "All Tests Passed! ✓"
echo "=========================================="
echo ""
echo "Summary:"
echo "  - Backend API: ${BACKEND_URL} (accessible)"
echo "  - Frontend UI: ${UI_URL} (accessible)"
echo "  - API Configuration: Correct"
echo "  - Chat Endpoint: Functional"
echo ""
echo "You can now access the application at:"
echo "  ${UI_URL}"
