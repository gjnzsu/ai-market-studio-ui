# Browser Testing Guide

## Pre-Test: Clear Browser Cache

**IMPORTANT:** Clear your browser cache first to ensure you're testing the new version.

### Chrome/Edge
1. Press `Ctrl+Shift+Delete`
2. Select "Cached images and files"
3. Click "Clear data"
4. **OR** Press `Ctrl+Shift+R` for hard refresh

### Firefox
1. Press `Ctrl+Shift+Delete`
2. Select "Cached Web Content"
3. Click "Clear Now"
4. **OR** Press `Ctrl+F5` for hard refresh

### Alternative: Use Incognito/Private Mode
- Chrome: `Ctrl+Shift+N`
- Firefox: `Ctrl+Shift+P`

---

## Test 1: Verify Configuration Loading

1. **Open the application:**
   - URL: http://136.116.205.168

2. **Open Developer Console:**
   - Press `F12` or `Ctrl+Shift+I`
   - Go to "Console" tab

3. **Check API_BASE_URL:**
   - Type in console: `window.ENV`
   - Press Enter
   - **Expected result:**
     ```javascript
     {API_BASE_URL: 'http://35.224.3.54'}
     ```
   - **If you see:** `undefined` or `{API_BASE_URL: 'http://localhost:8000'}` → Cache issue, do hard refresh

4. **Check API_BASE_URL variable:**
   - Type in console: `API_BASE_URL`
   - Press Enter
   - **Expected result:** `'http://35.224.3.54'`

---

## Test 2: Verify Network Requests

1. **Open Network Tab:**
   - Press `F12`
   - Go to "Network" tab
   - Check "Preserve log"

2. **Check env-config.js loads:**
   - Refresh the page (`Ctrl+Shift+R`)
   - Look for `env-config.js` in the network list
   - Click on it
   - **Check Response tab:**
     ```javascript
     window.ENV = {
       API_BASE_URL: 'http://35.224.3.54'
     };
     ```
   - **Check Headers tab:**
     - Look for `Cache-Control: no-cache, no-store, must-revalidate`
     - Look for `Pragma: no-cache`
     - Look for `Expires: 0`

---

## Test 3: Test Chat Functionality

1. **Type a query in the chat:**
   - Example: "What is the EUR/USD rate?"

2. **Watch the Network tab:**
   - You should see a POST request to `http://35.224.3.54/api/chat`
   - Status should be `200 OK`

3. **Check the response:**
   - Click on the `/api/chat` request
   - Go to "Response" tab
   - **Expected format:**
     ```json
     {
       "reply": "The EUR/USD rate is 1.0868 as of 2026-04-03.",
       "data": {...},
       "tool_used": "get_exchange_rate"
     }
     ```

4. **Check the UI:**
   - You should see the assistant's response in the chat
   - **Should NOT see:** "Network error: could not reach the backend."

---

## Test 4: Test Multiple Query Types

Try these different queries:

### Query 1: Exchange Rate
- **Input:** "What is GBP to USD?"
- **Expected:** Rate information displayed

### Query 2: News
- **Input:** "Show me latest FX news"
- **Expected:** News cards displayed with links

### Query 3: Market Insight
- **Input:** "Give me a market insight on EUR/USD"
- **Expected:** Rate chips and news cards displayed

---

## Test 5: Verify Cache Headers

1. **In Network tab, find env-config.js**
2. **Click on it**
3. **Go to "Headers" tab**
4. **Scroll to "Response Headers"**
5. **Verify these headers exist:**
   ```
   Cache-Control: no-cache, no-store, must-revalidate
   Pragma: no-cache
   Expires: 0
   ```

---

## Expected Results Summary

✅ **window.ENV.API_BASE_URL** = `'http://35.224.3.54'`
✅ **API_BASE_URL** = `'http://35.224.3.54'`
✅ **env-config.js** loads with correct content
✅ **Cache headers** prevent caching
✅ **Chat queries** work without network errors
✅ **Multiple query types** all work correctly

---

## Troubleshooting

### Issue: Still seeing "Network error"

**Solution:**
1. Hard refresh: `Ctrl+Shift+R`
2. Clear cache completely
3. Try incognito mode
4. Check console for actual error message

### Issue: window.ENV is undefined

**Solution:**
1. Check Network tab for env-config.js
2. Verify it loaded successfully (200 status)
3. Check the response content
4. Hard refresh the page

### Issue: API_BASE_URL is localhost:8000

**Solution:**
1. window.ENV didn't load properly
2. Hard refresh: `Ctrl+Shift+R`
3. Clear browser cache
4. Check env-config.js in Network tab

---

## Screenshot Checklist

Please take screenshots of:

1. ✅ Console showing `window.ENV` value
2. ✅ Console showing `API_BASE_URL` value
3. ✅ Network tab showing env-config.js response
4. ✅ Network tab showing cache-control headers
5. ✅ Successful chat query with response
6. ✅ Network tab showing POST to /api/chat with 200 status

---

## Report Back

After testing, please report:

1. **Did window.ENV load correctly?** (Yes/No)
2. **Did queries work without network errors?** (Yes/No)
3. **Which query types did you test?** (Rate/News/Insight)
4. **Any errors in console?** (Copy/paste if any)
5. **Screenshots** (if possible)

---

## Quick Test Command

If you want to test from command line first:

```bash
# Test env-config.js
curl http://136.116.205.168/env-config.js

# Test cache headers
curl -I http://136.116.205.168/env-config.js | grep -E "Cache|Pragma|Expires"

# Test API
curl -X POST http://35.224.3.54/api/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"test","history":[]}'
```

All should work correctly before browser testing.
