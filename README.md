# AI Market Studio - Frontend

Frontend application for the AI Market Studio conversational FX market data platform.

## Architecture

This is the frontend component of a microservices architecture:
- **Backend API**: [ai-market-studio](https://github.com/gjnzsu/ai-market-studio)
- **Frontend UI**: This repository

## Technology Stack

- HTML5
- JavaScript (Vanilla)
- CSS3
- Fetch API for backend communication

## Configuration

The frontend connects to the backend API via the `API_BASE_URL` configuration in `index.html`.

### Environment Variables

- `API_BASE_URL`: Backend API endpoint (default: `http://localhost:8000`)

## Development

1. Update the API endpoint in `index.html` if needed
2. Serve the file using any static server:
   ```bash
   python -m http.server 8080
   ```
3. Open `http://localhost:8080` in your browser

## Deployment

### Docker

```bash
docker build -t ai-market-studio-ui .
docker run -p 8080:80 ai-market-studio-ui
```

### Kubernetes

```bash
kubectl apply -f k8s/
```

## API Integration

The frontend communicates with the backend API at the configured `API_BASE_URL`. Ensure CORS is properly configured on the backend to allow requests from the frontend domain.

## License

MIT
