# War Room - News & Alerts Aggregator

A real-time web application that aggregates Ynet breaking news and Israeli Homefront Command alerts in a clean, two-column layout.

## Features

- **Real-time Updates**: Automatically refreshes every 30 seconds
- **Dual Data Sources**:
  - Ynet breaking news RSS feed
  - Israeli Homefront Command alerts
- **Modern UI**: Responsive design with Hebrew RTL support
- **Caching**: Server-side caching to reduce API calls
- **Error Handling**: Graceful fallbacks and error messages
- **Accessibility**: Keyboard shortcuts and screen reader friendly

## Quick Start

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Start the server**:
   ```bash
   npm start
   ```

3. **Open in browser**:
   ```
   http://localhost:3000
   ```

## Development

Run with auto-reload:
```bash
npm run dev
```

## API Endpoints

- `GET /api/ynet` - Fetch latest Ynet breaking news
- `GET /api/alerts` - Fetch current Homefront Command alerts
- `GET /api/health` - Health check endpoint

## Architecture

```
├── server.js          # Express server with API endpoints
├── public/
│   ├── index.html     # Main HTML page
│   ├── style.css      # Styles with RTL support
│   └── script.js      # Frontend JavaScript
└── package.json       # Dependencies and scripts
```

## Data Sources

- **Ynet RSS**: `https://www.ynet.co.il/Integration/StoryRss1854.xml`
- **Homefront Alerts**: `https://www.oref.org.il/warningMessages/alert/Alerts.json`
- **Alert Areas**: `https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he`
- **Fallback Alerts**: `https://api.tzevaadom.co.il/notifications`

All data comes directly from official Israeli government sources.

## Features

- ✅ Real-time data fetching
- ✅ Responsive design
- ✅ Hebrew RTL support
- ✅ Error handling
- ✅ Caching (30 seconds)
- ✅ Visual alerts for recent threats
- ✅ Auto-refresh on tab focus
- ✅ Keyboard shortcuts (Ctrl+R to refresh)

## Browser Support

Modern browsers with ES6+ support.
