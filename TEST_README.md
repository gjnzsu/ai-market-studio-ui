# AI Market Studio - Test Suite

This directory contains E2E tests for the AI Market Studio application.

## Test Scripts

### 1. `test_e2e_connectivity.sh`
Basic connectivity and health check tests.

**What it tests:**
- Backend API accessibility
- Frontend UI accessibility
- Environment configuration
- Chat endpoint functionality
- CORS configuration

**Run:**
```bash
bash test_e2e_connectivity.sh
```

### 2. `test_browser_simulation.sh`
Comprehensive browser behavior simulation.

**What it tests:**
- UI page loading
- Environment config injection
- CORS preflight requests
- Actual chat requests with Origin headers
- Multiple query types (news, rates)

**Run:**
```bash
bash test_browser_simulation.sh
```

## Deployment URLs

- **Frontend UI:** http://136.116.205.168
- **Backend API:** http://35.224.3.54
- **API Docs:** http://35.224.3.54/docs

## Configuration

The UI is configured to use the external backend IP via ConfigMap:
```yaml
API_BASE_URL: "http://35.224.3.54"
```

This is injected at runtime via `env-config.html` and the Docker entrypoint script.

## Troubleshooting

If tests fail:

1. **Check pod status:**
   ```bash
   kubectl get pods -n default | grep ai-market
   ```

2. **Check logs:**
   ```bash
   kubectl logs -n default deployment/ai-market-studio-ui
   kubectl logs -n default deployment/ai-market-studio
   ```

3. **Verify configuration:**
   ```bash
   kubectl exec -n default deployment/ai-market-studio-ui -- cat /usr/share/nginx/html/env-config.html
   ```

4. **Test backend directly:**
   ```bash
   curl -X POST http://35.224.3.54/api/chat \
     -H "Content-Type: application/json" \
     -d '{"message":"test","history":[]}'
   ```
