# Source Code Organization

This directory contains the refactored War Room application source code, organized for maintainability and scalability.

## Directory Structure

```
src/
├── config/
│   └── constants.js         # Application constants, API endpoints, cache settings
├── services/
│   ├── cache.service.js     # Cache utilities and withCache wrapper
│   ├── ynet.service.js      # Ynet RSS fetching & parsing
│   └── oref.service.js      # OREF alerts fetching & parsing  
├── utils/
│   ├── axios.util.js        # Axios configuration helpers
│   ├── html-parser.util.js  # Historical alerts HTML parsing utilities
│   └── data.util.js         # Data comparison, normalization utilities
├── routes/
│   └── api.routes.js        # HTTP API route handlers
├── websocket/
│   └── websocket.handler.js # WebSocket connection & real-time broadcasting
└── server.js                # Main server setup & application entry point
```

## Module Responsibilities

### Config
- **constants.js**: Centralized configuration for cache TTLs, API endpoints, application limits, and fallback data

### Services
- **cache.service.js**: NodeCache instance and generic caching wrapper utilities
- **ynet.service.js**: Ynet RSS feed fetching, XML parsing, and data transformation
- **oref.service.js**: OREF current/historical alerts, alert areas, with fallback handling

### Utils
- **axios.util.js**: Standardized HTTP client configuration with consistent headers/timeouts
- **html-parser.util.js**: Complex HTML parsing logic for historical alerts data extraction
- **data.util.js**: Common data processing, comparison, and normalization functions

### Routes
- **api.routes.js**: Express router with all HTTP API endpoints (`/api/ynet`, `/api/alerts`, etc.)

### WebSocket
- **websocket.handler.js**: WebSocket connection management, real-time data broadcasting, background polling

### Main
- **server.js**: Application entry point, Express server setup, middleware configuration

## Key Benefits

1. **Single Responsibility**: Each module has one clear purpose
2. **Testability**: Services and utilities can be tested in isolation
3. **Maintainability**: Easy to locate and modify specific functionality
4. **Scalability**: Simple to add new data sources or features
5. **Clear Dependencies**: Import structure shows relationships between modules

## Import Patterns

```javascript
// Config (no dependencies)
const { API_ENDPOINTS, CACHE_TTL } = require('../config/constants');

// Utils (minimal dependencies)
const { hasDataChanged } = require('../utils/data.util');

// Services (depend on utils/config)
const { fetchYnetData } = require('../services/ynet.service');

// Routes/WebSocket (depend on services)
const apiRoutes = require('./routes/api.routes');
```

This organization follows Node.js best practices and makes the codebase more professional and maintainable.
