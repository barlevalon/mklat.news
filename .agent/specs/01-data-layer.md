# Data Layer Specification

## Overview

The app fetches data directly from OREF and RSS APIs. No backend server. All network requests originate from the user's device.

> **Last validated**: 2026-03-04 — All endpoints confirmed live and functional.

## Data Sources

### OREF Current Alerts
- **URL**: `https://www.oref.org.il/warningMessages/alert/Alerts.json`
- **Poll Rate**: Every 2 seconds (foreground only)
- **Headers Required**:
  ```
  X-Requested-With: XMLHttpRequest
  Referer: https://www.oref.org.il/
  User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36
  ```
- **Response when no alerts**: UTF-8 BOM (`\xef\xbb\xbf`) + `\r\n` (5 bytes total). After stripping BOM and whitespace, this is an empty string.
- **Response when alerts active**: JSON object:
  ```json
  {
    "id": "133721700000000000",
    "cat": 1,
    "title": "ירי רקטות וטילים",
    "desc": "היכנסו למרחב המוגן",
    "data": ["תל אביב - מרכז העיר", "חיפה - מערב"]
  }
  ```
  - `id`: Unique alert identifier (string)
  - `cat`: Category number (1 = rockets, 2 = UAV, etc.)
  - `title`: Hebrew title of the alert type
  - `desc`: Hebrew instruction text
  - `data`: Array of location name strings
- **Server cache**: `max-age=3` (3 second CDN cache)

### OREF Alert History (JSON)
- **URL**: `https://www.oref.org.il/WarningMessages/alert/History/AlertsHistory.json`
- **Poll Rate**: Every 2 seconds (foreground only), alongside current alerts
- **Response**: JSON array of recent alert events (~370 KB, covers last ~1 hour):
  ```json
  [
    {
      "alertDate": "2026-03-04 14:09:32",
      "title": "ירי רקטות וטילים",
      "data": "גבעת הראל",
      "category": 1
    }
  ]
  ```
  - `alertDate`: Timestamp string (`YYYY-MM-DD HH:MM:SS`, Israel time)
  - `title`: Alert type title (Hebrew)
  - `data`: Single location name (string, not array)
  - `category`: Category number
- **Categories**:
  | category | title | meaning |
  |----------|-------|---------|
  | 1 | ירי רקטות וטילים | Active rocket/missile alert |
  | 2 | חדירת כלי טיס עוין | Active hostile UAV alert |
  | 13 | ...האירוע הסתיים | Event ended (clearance signal) |
  | 14 | בדקות הקרובות צפויות להתקבל התרעות באזורך | Imminent alert warning |

> **Note**: This endpoint replaces the legacy HTML endpoint (`GetAlerts.aspx`). It returns structured JSON (~370 KB) vs the HTML endpoint's ~10.5 MB of unparseable HTML. No regex parsing needed.

### OREF Legacy Historical Alerts (HTML) — DEPRECATED, DO NOT USE
- **URL**: `https://alerts-history.oref.org.il/Shared/Ajax/GetAlerts.aspx?lang=he`
- **Status**: Still functional but superseded by `AlertsHistory.json` above
- **Size**: ~10.5 MB HTML, ~15,000 entries
- **Issues**: Requires regex parsing, massive payload, same data available in JSON

### OREF Districts (Location List)
- **URL**: `https://alerts-history.oref.org.il/Shared/Ajax/GetDistricts.aspx?lang=he`
- **Poll Rate**: Once on app start, cache locally
- **Response**: JSON array of 1,526 entries (1,486 unique locations):
  ```json
  {
    "label": "אבו גוש",
    "value": "6657AD46BF8FA430B022FF282B7A804B",
    "id": "511",
    "areaid": 5,
    "areaname": "בית שמש",
    "label_he": "אבו גוש",
    "migun_time": 90
  }
  ```
  - `label` / `label_he`: Location name in Hebrew (identical in this endpoint)
  - `value`: Unique hash identifier
  - `id`: Numeric ID (string)
  - `areaid`: Region group ID (1-37)
  - `areaname`: Region name (33 regions: אילת, גולן, ירושלים, etc.)
  - `migun_time`: Shelter time in seconds (0, 15, 30, 45, 60, or 90)
- **Fallback URL**: `https://www.oref.org.il/districts/cities_heb.json`
  - 1,350 entries, different schema: `{areaid, cityAlId, id, label, rashut, color}`
  - Labels use pipe format: `"אבו גוש | אזור שפלת יהודה"` — need to split on ` | ` to get location name
  - Missing `migun_time` — Districts is the preferred source
  - 221 locations in Districts but not Cities, 84 vice versa — not fully synchronized
- **Ultimate fallback**: Hardcoded list of ~1,486 location names (update from current ~1,425)

### OREF Alert Translations (Bonus)
- **URL**: `https://www.oref.org.il/alerts/alertsTranslation.json`
- **Poll Rate**: Once on app start, cache locally
- **Response**: JSON array mapping `catId` to multilingual titles and descriptions (Hebrew, English, Russian, Arabic)
- **Useful for**: Future multi-language support (deferred), but also for mapping category IDs to human-readable alert types

### News RSS Feeds
| Source | URL | Poll Rate | Notes |
|--------|-----|-----------|-------|
| Ynet | `https://www.ynet.co.il/Integration/StoryRss1854.xml` | 30 seconds | Working |
| Maariv | `https://www.maariv.co.il/Rss/RssFeedsMivzakiChadashot` | 30 seconds | Returns 308 redirect to lowercase URL; HTTP client must follow redirects |
| Walla | `https://rss.walla.co.il/feed/22` | 30 seconds | Has timezone bug (from web app: times may need correction) |
| Haaretz | `https://www.haaretz.co.il/srv/rss---feedly` | 30 seconds | Working |

### Tzeva Adom Fallback
- **URL**: `https://api.tzevaadom.co.il/notifications`
- **Status**: Returns `[]` — functional but may be less reliable than primary OREF API
- **Use as**: Last-resort fallback if OREF current alerts endpoint fails

## Data Models

### Alert
```dart
class Alert {
  final String id;
  final String location;        // Location name (Hebrew), from `data` field
  final String title;           // Alert type title (Hebrew)
  final DateTime time;
  final int category;           // OREF category number
  final AlertCategory type;     // Derived from category
}

enum AlertCategory {
  rockets,         // category 1 — ירי רקטות וטילים
  uav,             // category 2 — חדירת כלי טיס עוין
  clearance,       // category 13 — האירוע הסתיים
  imminent,        // category 14 — בדקות הקרובות צפויות
  other,           // Any other category (earthquake, tsunami, hazmat, etc.)
}
```

### OrefLocation
```dart
class OrefLocation {
  final String name;            // label_he from Districts
  final String id;              // Numeric ID
  final String hashId;          // value (hash identifier)
  final int areaId;             // Region group ID
  final String areaName;        // Region name
  final int? shelterTimeSec;    // migun_time in seconds (null if from fallback source)
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
  final String orefName;       // Exact OREF location name (matches label_he)
  final String customLabel;    // User's label (e.g., "בית", "עבודה")
  final bool isPrimary;
  final int? shelterTimeSec;   // Cached from OrefLocation
}
```

## Polling Strategy

### Foreground Behavior
- Start polling when app enters foreground
- Stop all polling when app enters background
- Alerts (current + history): Poll every 2 seconds
- News: Poll every 30 seconds

### Resume Behavior
- Show "מתעדכן..." overlay
- Fetch fresh data immediately
- Update UI once data arrives
- Remove overlay

### Conditional Requests
- Use HTTP ETag/Last-Modified headers where supported (Alerts.json returns both)
- Cache OREF districts list locally (rarely changes)
- Cache alert translations locally (rarely changes)

## Response Normalization

### OREF Current Alerts
The OREF API returns varying formats:
- UTF-8 BOM + `\r\n` → No active alerts (empty)
- Empty string `""` → No active alerts
- JSON object with `data` array → Active alerts

Normalize: Strip BOM, trim whitespace. If empty string, return empty list. Otherwise parse JSON and extract `data` array as list of location strings, along with `cat`, `title`, `desc`, `id` from the parent object.

### OREF Alert History
Already structured JSON. Map each entry to `Alert` model using:
- `alertDate` → parse as Israel-timezone DateTime
- `data` → location name
- `title` → alert title
- `category` → alert category, derive `AlertCategory` enum

## Acceptance Criteria

- [ ] App successfully fetches current alerts from OREF API
- [ ] App successfully fetches alert history from JSON endpoint
- [ ] App successfully fetches location list with shelter times from Districts endpoint
- [ ] App successfully fetches and parses all 4 RSS feeds
- [ ] Maariv RSS redirect is followed correctly
- [ ] Polling starts on foreground, stops on background
- [ ] Data models correctly represent all response variants
- [ ] Failed API calls do not crash the app
- [ ] Network errors are surfaced to error handling layer
- [ ] BOM handling works correctly for empty alerts response

## References

- OREF API validated: 2026-03-04
- `oref` Python library (PyPI) confirms Alerts.json format
- `amitfin/oref_alert` Home Assistant integration (latest: v5.8.0, 2026-03-01) — most maintained community project
- Existing web app: `src/services/oref.service.js`, `src/config/constants.js`
