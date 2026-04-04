# RAG Sources Deduplication Fix

## Problem
The RAG service was returning duplicate source filenames in the UI:
```
Sources:
Monthly Foreign Exchange Outlook.pdf
Monthly Foreign Exchange Outlook.pdf
FX_Outlook_2026_Nov_2025.pdf
FX_Outlook_2026_Nov_2025.pdf
FX_Outlook_2026_Nov_2025.pdf
```

## Root Cause
The RAG service returns multiple chunks from the same document (by design for better retrieval), but the frontend was displaying all sources without deduplication.

## Solution
Added deduplication logic in `index.html` line 516-517:
```javascript
// Deduplicate sources by name
const uniqueSources = [...new Set(data.data.sources.map(s => s.name || s))];
const sourcesHtml = uniqueSources.map(s => `<li>${s}</li>`).join('');
```

This uses JavaScript `Set` to remove duplicate source names before rendering.

## Deployment
1. Start Docker Desktop
2. Run: `bash deploy-fix.sh`
3. Test at http://136.116.205.168

## Expected Result
```
Sources:
Monthly Foreign Exchange Outlook.pdf
FX_Outlook_2026_Nov_2025.pdf
```

Each unique source document appears only once.
