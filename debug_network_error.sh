#!/bin/bash
# Debug script to help diagnose the network error

echo "=========================================="
echo "Network Error Debugging"
echo "=========================================="
echo ""

echo "1. Check what the browser loads:"
echo "   Visit: http://136.116.205.168/env-config.html"
echo "   Should show: API_BASE_URL: 'http://35.224.3.54'"
echo ""

echo "2. Open browser console (F12) and check:"
echo "   - What is the value of API_BASE_URL?"
echo "   - What is the actual fetch URL being called?"
echo "   - What is the exact error message?"
echo ""

echo "3. Test API directly from command line:"
curl -X POST http://35.224.3.54/api/chat \
  -H "Content-Type: application/json" \
  -H "Origin: http://136.116.205.168" \
  -d '{"message":"test","history":[]}' 2>&1
echo ""
echo ""

echo "4. Check CORS preflight:"
curl -I -X OPTIONS http://35.224.3.54/api/chat \
  -H "Origin: http://136.116.205.168" \
  -H "Access-Control-Request-Method: POST" 2>&1 | grep -i "access-control"
echo ""

echo "=========================================="
echo "Possible Issues:"
echo "=========================================="
echo "1. Browser cache - Try hard refresh (Ctrl+Shift+R)"
echo "2. Check browser console for actual error"
echo "3. Verify API_BASE_URL in browser console"
echo ""
echo "To clear browser cache:"
echo "  - Chrome: Ctrl+Shift+Delete > Clear cached images and files"
echo "  - Firefox: Ctrl+Shift+Delete > Cached Web Content"
echo ""
