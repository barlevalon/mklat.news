# Data Layer Specification

## Overview

The app fetches data directly from OREF and RSS APIs. No backend server. All network requests originate from the user's device.

## Data Sources

### OREF Current Alerts
- **URL**: `https://www.oref.org.il/warningMessages/alert/Alerts.json`
- **Poll Rate**: Every 2 seconds (foreground only)
- **Response**: JSON array of active alerts, or empty string/array when no alerts
- **Headers Required**:
  ```
  X-Requested-With: XMLHttpRequest
  Referer: https://www.oref.org.il/
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
  ```

### OREF Historical Alerts
- **URL**: `https://alerts-history.oref.org.il/Shared/Ajax/GetAlerts.aspx?lang=he`
- **Poll Rate**: Every 2 seconds (foreground only)
- **Response**: HTML containing alert history table
- **Contains**: Recent alerts with timestamps, locations, descriptions, clearance messages

### OREF Districts (Location List)
- **URL**: `https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he`
- **Poll Rate**: Once on app start, cache locally
- **Fallback URL**: `https://www.oref.org.il/districts/cities_heb.json`
- **Response**: JSON array of location names (~1,425 locations)

### News RSS Feeds
| Source | URL | Poll Rate |
|--------|-----|-----------|
| Ynet | `https://www.ynet.co.il/Integration/StoryRss1854.xml` | 30 seconds |
| Maariv | `https://www.maariv.co.il/Rss/RssFeedsMivzakiChadashot` | 30 seconds |
| Walla | `https://rss.walla.co.il/feed/22` | 30 seconds |
| Haaretz | `https://www.haaretz.co.il/srv/rss---feedly` | 30 seconds |

## Data Models

### Alert
```dart
class Alert {
  final String id;
  final String area;           // Location name (Hebrew)
  final String description;    // Alert type or clearance message
  final DateTime time;
  final bool isActive;         // Currently active vs historical
  final AlertType type;        // red_alert, imminent, clearance, etc.
}

enum AlertType {
  redAlert,        // צבע אדום
  imminent,        // התרעה צפויה
  partialClear,    // ניתן לצאת אך הישארו בקרבת המרחב
  fullClear,       // האירוע הסתיים
  historical,      // Past alert from history
}
```

### NewsItem
```dart
class NewsItem {
  final String id;
  final String title;
  final String? description;
  final String link;
  final DateTime pubDate;
  final NewsSource source;
}

enum NewsSource { ynet, maariv, walla, haaretz }
```

### SavedLocation
```dart
class SavedLocation {
  final String id;
  final String orefName;       // Exact OREF location name
  final String customLabel;    // User's label (e.g., "בית", "עבודה")
  final bool isPrimary;
}
```

## Polling Strategy

### Foreground Behavior
- Start polling when app enters foreground
- Stop all polling when app enters background
- Alerts: Poll every 2 seconds
- News: Poll every 30-60 seconds

### Resume Behavior
- Show "מתעדכן..." overlay
- Fetch fresh data immediately
- Update UI once data arrives
- Remove overlay

### Conditional Requests
- Use HTTP ETag/Last-Modified headers where supported
- Cache OREF districts list locally (rarely changes)

## Response Normalization

### OREF Alerts Response Formats
The OREF API returns varying formats:
- Empty string `""` or `"\r\n"` → No active alerts
- JSON array of strings `["תל אביב", "חיפה"]` → Location names only
- JSON array of objects `[{data: "תל אביב", ...}]` → Full alert objects

Normalize all formats to consistent `List<Alert>` structure.

### Historical Alerts HTML Parsing
The historical alerts endpoint returns HTML. Parse to extract:
- Alert time
- Location(s)
- Description (alert type or clearance message)
- Use patterns from existing `src/utils/html-parser.util.js`

## Acceptance Criteria

- [ ] App successfully fetches current alerts from OREF API
- [ ] App successfully fetches historical alerts and parses HTML
- [ ] App successfully fetches location list from OREF
- [ ] App successfully fetches and parses all 4 RSS feeds
- [ ] Polling starts on foreground, stops on background
- [ ] Data models correctly represent all response variants
- [ ] Failed API calls do not crash the app
- [ ] Network errors are surfaced to error handling layer

## References

Existing web app implementation:
- `src/services/oref.service.js` - OREF API integration
- `src/utils/html-parser.util.js` - Historical alerts parsing
- `src/config/constants.js` - API endpoints, fallback location list
