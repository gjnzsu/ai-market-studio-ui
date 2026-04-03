# AI Market Studio - Frontend

Frontend application for the AI Market Studio conversational FX market data platform.

## Architecture

This repository is part of a **microservices architecture** that was split from a monolithic application for better scalability and independent deployment:

- **Backend API**: [ai-market-studio](https://github.com/gjnzsu/ai-market-studio) - FastAPI service (port 8000)
- **Frontend UI**: This repository - Static HTML/JS served via nginx (port 80)
- **RAG Service**: [ai-rag-service](https://github.com/gjnzsu/ai-rag-service) - Research document query service

### Why Microservices?

The original monolithic application was split to achieve:
- **Independent scaling**: Frontend and backend can scale separately based on load
- **Independent deployment**: Deploy UI changes without restarting the backend
- **Technology flexibility**: Frontend uses static HTML/JS, backend uses FastAPI
- **Better resource utilization**: Each service has its own resource limits

## Live Deployment

The application is deployed on Google Kubernetes Engine (GKE):

| Component | URL | Status |
|-----------|-----|--------|
| **Frontend UI** | http://136.116.205.168 | ✓ Running (2 replicas) |
| **Backend API** | http://35.224.3.54 | ✓ Running (1 replica) |
| **API Docs** | http://35.224.3.54/docs | ✓ Available |

**GKE Cluster:** `helloworld-cluster` (us-central1)
**GCP Project:** `gen-lang-client-0896070179`

## Technology Stack

- HTML5
- JavaScript (Vanilla)
- CSS3
- Chart.js for inline visualizations
- Fetch API for backend communication
- nginx for static file serving

## Configuration

The frontend connects to the backend API via environment variable injection at runtime.

### Environment Variables

- `API_BASE_URL`: Backend API endpoint
  - **Local development**: `http://localhost:8000`
  - **GKE production**: `http://35.224.3.54` (external LoadBalancer IP)

The `API_BASE_URL` is injected via:
1. `env-config.html` template with `${API_BASE_URL}` placeholder
2. `docker-entrypoint.sh` uses `envsubst` to replace the placeholder
3. ConfigMap provides the value in Kubernetes

## Development

### Local Development

1. Start the backend API first (see [ai-market-studio](https://github.com/gjnzsu/ai-market-studio))
2. Update `API_BASE_URL` in `env-config.html` if needed (default: `http://localhost:8000`)
3. Serve the frontend:
   ```bash
   python -m http.server 8080
   ```
4. Open `http://localhost:8080` in your browser

### Testing

Run the E2E test suite to verify connectivity:

```bash
# Basic connectivity tests
bash test_e2e_connectivity.sh

# Comprehensive browser simulation
bash test_browser_simulation.sh
```

See [TEST_README.md](TEST_README.md) for detailed test documentation.

## Deployment

### Docker

Build and run locally:

```bash
docker build -t ai-market-studio-ui .
docker run -p 8080:80 -e API_BASE_URL=http://localhost:8000 ai-market-studio-ui
```

### Kubernetes (GKE)

1. **Build and push the image:**

```bash
gcloud auth configure-docker
docker build -t gcr.io/gen-lang-client-0896070179/ai-market-studio-ui:latest .
docker push gcr.io/gen-lang-client-0896070179/ai-market-studio-ui:latest
```

2. **Update ConfigMap** (if backend URL changed):

```bash
# Edit k8s/configmap.yaml to set API_BASE_URL
kubectl apply -f k8s/configmap.yaml
```

3. **Deploy to GKE:**

```bash
kubectl apply -f k8s/
kubectl rollout restart deployment/ai-market-studio-ui
kubectl rollout status deployment/ai-market-studio-ui --timeout=60s
```

4. **Get the external IP:**

```bash
kubectl get service ai-market-studio-ui
```

## API Integration

The frontend communicates with the backend API at the configured `API_BASE_URL`.

### Backend Endpoints Used

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/chat` | POST | Main chat interface with GPT-4o agent |
| `/api/rates/historical` | POST | Historical FX rate data |
| `/api/dashboard` | POST | Batch panel data for dashboards |

### CORS Configuration

The backend must allow requests from the frontend origin. In production, the backend ConfigMap includes:

```yaml
CORS_ORIGINS: "http://136.116.205.168"
```

## Features

- **Natural Language Chat**: Ask questions like "What is EUR/USD rate?"
- **Inline Visualizations**: Charts render directly in chat bubbles
- **Market News**: Latest FX news from RSS feeds
- **Research Query**: Search internal research documents via RAG service
- **Market Insights**: Combined rate + news summaries

## Troubleshooting

### Network Errors

If you see "network error" when making queries:

1. **Check API configuration:**
   ```bash
   curl http://136.116.205.168/env-config.html
   # Should show: API_BASE_URL: 'http://35.224.3.54'
   ```

2. **Verify backend is accessible:**
   ```bash
   curl http://35.224.3.54/docs
   # Should return 200 OK
   ```

3. **Check CORS headers:**
   ```bash
   curl -I -X OPTIONS http://35.224.3.54/api/chat \
     -H "Origin: http://136.116.205.168"
   # Should include Access-Control-Allow-Origin header
   ```

4. **Run the test suite:**
   ```bash
   bash test_e2e_connectivity.sh
   ```

### Common Issues

- **"API_BASE_URL is localhost"**: ConfigMap not applied or pods not restarted
- **CORS errors**: Backend CORS_ORIGINS doesn't include frontend URL
- **404 on /api/chat**: Backend not running or wrong URL

## License

MIT
