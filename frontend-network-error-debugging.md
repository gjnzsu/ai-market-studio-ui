---
name: frontend-network-error-debugging
description: Systematic debugging workflow for frontend "network error" issues when browser cannot reach backend API. Use when users report network errors but backend API is accessible via curl.
---

# Frontend Network Error Debugging

## When to Use This Skill

Use this skill when:
- Users report "network error" or "could not reach backend" in browser
- Backend API responds correctly to curl/Postman
- Frontend works locally but fails in production
- Network errors occur after deployment
- JavaScript fetch/axios calls fail silently

**Do NOT use for:**
- Actual network connectivity issues
- Backend server crashes
- CORS errors (visible in console)
- DNS resolution failures

## Debugging Workflow

### Phase 1: Verify the Basics

**1. Test Backend Directly**
```bash
# Verify backend is accessible
curl http://<backend-url>/health
curl http://<backend-url>/docs

# Test actual endpoint
curl -X POST http://<backend-url>/api/endpoint \
  -H "Content-Type: application/json" \
  -d '{"test":"data"}'
```

**Expected:** Backend responds correctly
**If fails:** This is a backend issue, not frontend config

**2. Test Frontend Loads**
```bash
# Verify frontend is accessible
curl http://<frontend-url>/

# Check status code
curl -I http://<frontend-url>/
```

**Expected:** 200 OK with HTML content
**If fails:** Frontend deployment issue

### Phase 2: Check Configuration Loading

**3. Inspect Configuration File**
```bash
# Check what configuration browser receives
curl http://<frontend-url>/env-config.js
# or
curl http://<frontend-url>/config.json
```

**Look for:**
- ✓ File exists (not 404)
- ✓ Contains correct backend URL
- ✓ Valid JavaScript/JSON syntax
- ✗ HTML content (wrong file type)
- ✗ Localhost URLs in production
- ✗ Internal DNS names (not accessible from browser)

**Common Issues:**
- File is HTML being loaded as JavaScript
- Contains `${VARIABLE}` placeholders (not substituted)
- Points to internal Kubernetes DNS (e.g., `http://service-name:8000`)
- Points to localhost

**4. Check Browser Console**

Open browser DevTools (F12) and check:

```javascript
// In Console tab, check configuration
window.ENV
window.CONFIG
API_BASE_URL

// Check what URL is actually being used
// Look at the fetch call in your code
```

**Expected:** Configuration variables are defined with correct URLs
**If undefined:** Configuration file didn't load or execute

**5. Check Network Tab**

In DevTools Network tab:
- Find the config file request (env-config.js, config.json)
- Check Status: Should be 200
- Check Response: Should contain correct URL
- Check if it's being loaded at all

### Phase 3: Check Caching Issues

**6. Check Cache Headers**
```bash
curl -I http://<frontend-url>/env-config.js
```

**Look for:**
- `Cache-Control: no-cache` (good)
- `Cache-Control: max-age=31536000` (bad for config files)
- `ETag` and `Last-Modified` (check if stale)

**7. Test with Cache Buster**
```bash
curl http://<frontend-url>/env-config.js?v=$(date +%s)
```

**If this returns correct content but regular URL doesn't:**
→ Caching issue (LoadBalancer, CDN, or browser)

**8. Check LoadBalancer/CDN Cache**

For Kubernetes LoadBalancer:
```bash
# Force pod restart to clear any cache
kubectl delete pods -l app=<frontend-app>
kubectl rollout status deployment/<frontend-app>

# Wait 30 seconds for LoadBalancer cache to clear
sleep 30

# Test again
curl http://<frontend-url>/env-config.js
```

### Phase 4: Verify Docker Image

**9. Check What's Actually in the Image**
```bash
# Check if file exists in image
docker run --rm <image> ls -la /usr/share/nginx/html/

# Check file content
docker run --rm <image> cat /usr/share/nginx/html/env-config.js

# Check if references are updated
docker run --rm <image> cat /usr/share/nginx/html/index.html | grep config
```

**Common Issues:**
- Old file still in image (Docker cache)
- File not copied (Dockerfile error)
- Wrong file name (renamed but references not updated)

**10. Verify Build Process**
```bash
# Rebuild without cache
docker build --no-cache -t <image> .

# Verify the new image
docker run --rm <image> cat /usr/share/nginx/html/env-config.js
```

### Phase 5: Check CORS (If Applicable)

**11. Test CORS Preflight**
```bash
curl -I -X OPTIONS http://<backend-url>/api/endpoint \
  -H "Origin: http://<frontend-url>" \
  -H "Access-Control-Request-Method: POST" \
  -H "Access-Control-Request-Headers: content-type"
```

**Expected Headers:**
```
Access-Control-Allow-Origin: http://<frontend-url>
Access-Control-Allow-Methods: POST, GET, OPTIONS
Access-Control-Allow-Headers: content-type
```

**If missing:** CORS not configured correctly

### Phase 6: Check Environment Variable Substitution

**12. Verify Runtime Substitution**

If using environment variable substitution (envsubst):

```bash
# Check entrypoint script
docker run --rm <image> cat /docker-entrypoint.sh

# Check if substitution happens
kubectl exec deployment/<frontend-app> -- cat /usr/share/nginx/html/env-config.js
```

**Look for:**
- ✗ `${API_BASE_URL}` (not substituted)
- ✓ `http://actual-url` (substituted correctly)

**Common Issues:**
- Entrypoint script not running
- Wrong variable name in ConfigMap
- Syntax error in substitution

## Common Root Causes

### 1. Wrong File Type
**Symptom:** Config file is HTML but loaded as JavaScript
**Detection:** `curl` shows `<!DOCTYPE html>` in config file
**Fix:** Convert to pure JavaScript or JSON

### 2. Internal DNS in Browser
**Symptom:** Config points to `http://service-name:8000`
**Detection:** Browser cannot resolve internal Kubernetes DNS
**Fix:** Use external LoadBalancer IP or domain

### 3. Docker Build Cache
**Symptom:** Old file content in deployed image
**Detection:** Image contains old file despite local changes
**Fix:** `docker build --no-cache`

### 4. LoadBalancer Caching
**Symptom:** Correct content in pods, wrong content via URL
**Detection:** Cache buster URL works, regular URL doesn't
**Fix:** Wait for cache TTL or restart pods

### 5. Missing Environment Substitution
**Symptom:** Config contains `${VARIABLE}` placeholders
**Detection:** Literal `${...}` in browser
**Fix:** Check entrypoint script runs envsubst

### 6. Browser Cache
**Symptom:** Works in incognito, fails in regular browser
**Detection:** Hard refresh fixes it
**Fix:** Add cache-control headers, user hard refresh

## Prevention Checklist

After fixing, implement these to prevent recurrence:

### 1. Use Proper File Extensions
```
✓ env-config.js (for JavaScript)
✓ config.json (for JSON)
✗ env-config.html (confusing)
```

### 2. Add Cache-Control Headers
```nginx
location = /env-config.js {
    add_header Cache-Control "no-cache, no-store, must-revalidate";
    add_header Pragma "no-cache";
    add_header Expires "0";
}
```

### 3. Create Image Verification Script
```bash
#!/bin/bash
# verify-image.sh
IMAGE=$1

echo "Checking config file..."
docker run --rm $IMAGE cat /usr/share/nginx/html/env-config.js

echo "Checking references..."
docker run --rm $IMAGE cat /usr/share/nginx/html/index.html | grep config
```

### 4. Add Browser-Based E2E Tests
```javascript
// Test configuration loads correctly
test('config loads with correct API URL', async ({ page }) => {
  await page.goto('http://frontend-url');
  const apiUrl = await page.evaluate(() => window.ENV?.API_BASE_URL);
  expect(apiUrl).toBe('http://expected-backend-url');
});
```

### 5. Document Deployment Process
```markdown
## Deployment Checklist
- [ ] Build with --no-cache
- [ ] Verify image contents
- [ ] Test config file loads
- [ ] Check cache headers
- [ ] Test in actual browser
- [ ] Wait for cache to clear
```

## Testing Strategy

### Test Locally First
```bash
# 1. Test backend
curl http://localhost:8000/api/endpoint

# 2. Test frontend serves files
python -m http.server 8080

# 3. Test in browser
# Open http://localhost:8080
# Check console: window.ENV
```

### Test in Production
```bash
# 1. Test backend directly
curl http://production-backend/api/endpoint

# 2. Test config file
curl http://production-frontend/env-config.js

# 3. Test cache headers
curl -I http://production-frontend/env-config.js

# 4. Test in browser
# Open DevTools, check Network and Console tabs
```

## Diagnostic Commands

```bash
# Quick diagnostic script
#!/bin/bash
FRONTEND_URL="http://your-frontend"
BACKEND_URL="http://your-backend"

echo "=== Backend Health ==="
curl -s $BACKEND_URL/health || echo "FAIL"

echo -e "\n=== Frontend Config ==="
curl -s $FRONTEND_URL/env-config.js

echo -e "\n=== Cache Headers ==="
curl -I $FRONTEND_URL/env-config.js | grep -E "Cache|Pragma|Expires"

echo -e "\n=== CORS Check ==="
curl -I -X OPTIONS $BACKEND_URL/api/chat \
  -H "Origin: $FRONTEND_URL" \
  -H "Access-Control-Request-Method: POST" | grep "Access-Control"
```

## Key Insights

1. **curl ≠ browser** - API working via curl doesn't mean browser can reach it
2. **Test the full stack** - Test from browser, not just command line
3. **Check every layer** - Config file → Docker image → Pods → LoadBalancer → Browser
4. **Cache is everywhere** - Docker, LoadBalancer, CDN, browser all cache
5. **Verify before deploy** - Check image contents before pushing to production

## Example: Real Incident

**Symptom:** "Network error: could not reach backend" in browser

**Investigation:**
1. ✓ Backend responds to curl
2. ✓ Frontend loads
3. ✗ Config file is HTML (should be JavaScript)
4. ✗ Browser tries to execute HTML as JavaScript
5. ✗ window.ENV undefined, falls back to localhost:8000
6. ✗ Browser tries localhost, fails with network error

**Root Cause:** env-config.html was HTML file being loaded via `<script src="env-config.html">`

**Fix:**
1. Convert to pure JavaScript
2. Rename to env-config.js
3. Rebuild with --no-cache
4. Add cache-control headers
5. Create verification script

**Prevention:**
- Use .js extension for JavaScript files
- Verify image contents before deployment
- Add browser-based E2E tests
- Document deployment checklist

## Summary

Frontend network errors when backend is accessible usually indicate:
1. Configuration not loading correctly
2. Wrong URL in configuration (internal DNS, localhost)
3. Caching serving stale content
4. Docker image contains old files

**Always test in actual browser, not just with curl.**
