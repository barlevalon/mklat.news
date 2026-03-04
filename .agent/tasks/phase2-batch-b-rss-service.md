# Phase 2 Batch B: RSS News Service

## Context

Implement the RSS news service that fetches and parses headlines from 4 Israeli news sources. This service is independent of the OREF services.

Read these files before starting:
- `.agent/specs/01-data-layer.md` — RSS feed section (line 106-112)
- `.agent/specs/04-news-screen.md` — news display requirements
- `lib/core/api_endpoints.dart` — RSS feed URLs
- `lib/data/models/news_item.dart` — NewsItem model
- `lib/data/services/http_client.dart` — HTTP client (created in Batch A; if not yet present, create it per the Batch A spec at `.agent/tasks/phase2-batch-a-oref-services.md`)

## Architecture

```
lib/data/services/
└── rss_news_service.dart    # RSS feed fetcher + parser
```

---

## Task 1: RSS News Service

**File:** `lib/data/services/rss_news_service.dart`

Fetches and parses RSS feeds from 4 news sources. Uses the `xml` package for XML parsing.

### Design

```dart
import 'package:xml/xml.dart';
import '../../core/api_endpoints.dart';
import '../models/news_item.dart';
import 'http_client.dart';

class RssNewsService {
  final HttpClient _httpClient;

  RssNewsService(this._httpClient);

  /// Fetch news from all RSS sources.
  /// Returns combined list sorted by pubDate (newest first).
  /// Individual feed failures are silently ignored — returns whatever succeeds.
  Future<List<NewsItem>> fetchAllNews() async {
    final results = await Future.wait([
      _fetchFeed(ApiEndpoints.rssYnet, NewsSource.ynet),
      _fetchFeed(ApiEndpoints.rssMaariv, NewsSource.maariv),
      _fetchFeed(ApiEndpoints.rssWalla, NewsSource.walla),
      _fetchFeed(ApiEndpoints.rssHaaretz, NewsSource.haaretz),
    ]);

    final allItems = results.expand((items) => items).toList();
    allItems.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allItems;
  }

  /// Fetch and parse a single RSS feed. Returns [] on any error.
  Future<List<NewsItem>> _fetchFeed(String url, NewsSource source) async {
    try {
      final body = await _httpClient.get(url);
      return _parseRssFeed(body, source);
    } catch (e) {
      return [];
    }
  }

  /// Parse RSS XML into NewsItem list.
  List<NewsItem> _parseRssFeed(String xmlStr, NewsSource source) {
    try {
      final document = XmlDocument.parse(xmlStr);
      final items = document.findAllElements('item');

      return items.map((item) {
        final title = _extractText(item, 'title');
        final link = _extractText(item, 'link');
        final description = _extractText(item, 'description');
        final pubDateStr = _extractText(item, 'pubDate');

        if (title.isEmpty || link.isEmpty) return null;

        final pubDate = _parsePubDate(pubDateStr, source);

        return NewsItem(
          id: link, // Use URL as unique ID
          title: _stripCdata(title),
          description: description.isNotEmpty
              ? _stripHtml(_stripCdata(description)).trim()
              : null,
          link: link,
          pubDate: pubDate,
          source: source,
        );
      }).whereType<NewsItem>().toList();
    } catch (e) {
      return [];
    }
  }
}
```

### Critical: Walla Timezone Bug

From the legacy web app (`combined-news.service.js` lines 20-26) and the spec:

Walla's RSS feed includes `pubDate` values like `"Thu, 04 Mar 2026 14:30:00 GMT"` but the times are actually **Israel local time**, not GMT. The fix:

```dart
DateTime _parsePubDate(String dateStr, NewsSource source) {
  if (dateStr.isEmpty) return DateTime.now();

  try {
    if (source == NewsSource.walla) {
      // Walla bug: times labeled GMT are actually Israel time (GMT+2 or GMT+3)
      // Remove "GMT" so it's parsed as-is without timezone offset
      final fixedStr = dateStr.replaceAll('GMT', '').trim();
      return HttpDate.parse(fixedStr);  // won't work — use manual parse
    }
    return _parseRfc2822Date(dateStr);
  } catch (e) {
    return DateTime.now();
  }
}
```

Actually, Dart's standard library doesn't have a great RFC 2822 date parser. Implement a simple one:

```dart
/// Parse RFC 2822 date format commonly used in RSS feeds.
/// Example: "Thu, 04 Mar 2026 14:30:00 +0200"
/// Example: "Thu, 04 Mar 2026 14:30:00 GMT"
DateTime _parsePubDate(String dateStr, NewsSource source) {
  if (dateStr.isEmpty) return DateTime.now();

  try {
    var cleaned = dateStr.trim();

    if (source == NewsSource.walla) {
      // Walla timezone bug: times labeled GMT are actually Israel time.
      // Remove timezone indicator so DateTime parses as local time.
      cleaned = cleaned.replaceAll(RegExp(r'\s*(GMT|UTC|[+-]\d{4})\s*$'), '');
    }

    return _parseRfc2822(cleaned);
  } catch (e) {
    return DateTime.now();
  }
}

static final _months = {
  'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
  'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
};

/// Parse RFC 2822 date string to DateTime.
/// Handles: "Thu, 04 Mar 2026 14:30:00 +0200"
/// Also handles: "04 Mar 2026 14:30:00"
DateTime _parseRfc2822(String input) {
  // Remove day name prefix if present (e.g., "Thu, ")
  final cleaned = input.replaceFirst(RegExp(r'^[A-Za-z]{3},?\s*'), '');

  // Parse: "04 Mar 2026 14:30:00 +0200" or "04 Mar 2026 14:30:00"
  final parts = cleaned.split(RegExp(r'\s+'));
  // parts[0] = "04", parts[1] = "Mar", parts[2] = "2026", parts[3] = "14:30:00", parts[4] = "+0200" (optional)

  final day = int.parse(parts[0]);
  final month = _months[parts[1].toLowerCase()]!;
  final year = int.parse(parts[2]);

  final timeParts = parts[3].split(':');
  final hour = int.parse(timeParts[0]);
  final minute = int.parse(timeParts[1]);
  final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

  if (parts.length > 4) {
    // Has timezone offset like "+0200" or "GMT"
    final tz = parts[4];
    if (tz == 'GMT' || tz == 'UTC') {
      return DateTime.utc(year, month, day, hour, minute, second);
    }
    // Parse numeric offset like "+0200" or "-0500"
    final sign = tz.startsWith('-') ? -1 : 1;
    final offsetStr = tz.replaceFirst(RegExp(r'[+-]'), '');
    final offsetHours = int.parse(offsetStr.substring(0, 2));
    final offsetMinutes = int.parse(offsetStr.substring(2, 4));
    final offset = Duration(hours: offsetHours, minutes: offsetMinutes) * sign;
    return DateTime.utc(year, month, day, hour, minute, second).subtract(offset);
  }

  // No timezone — treat as local time
  return DateTime(year, month, day, hour, minute, second);
}
```

### Helper Methods

```dart
/// Strip CDATA wrapper from RSS content.
/// Input: "<![CDATA[Actual content]]>" → Output: "Actual content"
String _stripCdata(String input) {
  return input.replaceAllMapped(
    RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
    (match) => match.group(1) ?? '',
  );
}

/// Strip HTML tags from a string.
/// Input: "<p>Hello <b>world</b></p>" → Output: "Hello world"
String _stripHtml(String input) {
  return input.replaceAll(RegExp(r'<[^>]*>'), '');
}

/// Extract text content of a named element from an RSS item.
String _extractText(XmlElement item, String elementName) {
  final element = item.findElements(elementName).firstOrNull;
  if (element == null) return '';
  return element.innerText;
}
```

### Maariv Redirect

Maariv's RSS URL returns a 308 redirect. The `http` package follows redirects by default, so no special handling is needed. The test should verify this works.

### Description Truncation

The spec (04-news-screen.md) mentions truncating descriptions to ~100 chars for display. That's a **UI concern**, not a service concern. The service returns the full description. Truncation will happen in the presentation layer.

---

## Task 2: Unit Tests

**File:** `test/unit/rss_news_service_test.dart`

Use mockito to mock the HTTP client. Provide realistic RSS XML strings as test data.

### Test cases:

1. **Basic RSS parsing** — valid Ynet-style RSS XML returns correct NewsItem list
2. **CDATA stripping** — titles/descriptions wrapped in CDATA are cleaned
3. **HTML stripping** — HTML tags in descriptions are removed
4. **Walla timezone bug** — Walla dates labeled GMT are parsed as local time (not converted)
5. **Multiple feeds combined** — all 4 feeds return items, combined list is sorted by pubDate newest-first
6. **Individual feed failure** — one feed fails, others still returned
7. **All feeds fail** — returns `[]`
8. **Invalid XML** — returns `[]`
9. **Missing title or link** — items without title or link are filtered out
10. **Empty description** — description is null when empty/missing

### Sample RSS XML for tests:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Ynet Breaking News</title>
    <item>
      <title><![CDATA[פיצוץ נשמע באזור הדרום]]></title>
      <link>https://www.ynet.co.il/article/123</link>
      <description><![CDATA[<p>תקציר קצר של הכתבה</p>]]></description>
      <pubDate>Thu, 04 Mar 2026 14:30:00 +0200</pubDate>
    </item>
    <item>
      <title><![CDATA[כותרת שנייה]]></title>
      <link>https://www.ynet.co.il/article/456</link>
      <pubDate>Thu, 04 Mar 2026 14:00:00 +0200</pubDate>
    </item>
  </channel>
</rss>
```

### Mocking pattern:

Mock the `HttpClient` class (our wrapper, not `http.Client` directly). This is simpler since we control the interface:

```dart
// Create a mock for our HttpClient wrapper
class MockHttpClient extends Mock implements HttpClient {}

// In tests:
final mockClient = MockHttpClient();
when(mockClient.get(ApiEndpoints.rssYnet)).thenAnswer((_) async => validRssXml);
when(mockClient.get(ApiEndpoints.rssMaariv)).thenThrow(Exception('Network error'));
```

Wait — `HttpClient` is a concrete class, not an interface. To mock it with mockito, we need `@GenerateMocks([HttpClient])`. But actually, since we control it, we can use manual mocks or add `@GenerateMocks`. Use `@GenerateMocks([HttpClient])` and import the generated mock.

**Actually**, for cleaner testability, all service tests should mock `HttpClient`. Create a shared mock:

**File:** `test/mocks/mock_http_client.dart`
```dart
import 'package:mockito/annotations.dart';
import 'package:mklat/data/services/http_client.dart';

@GenerateMocks([HttpClient])
export 'mock_http_client.mocks.dart';
```

Then all test files can import this shared mock. Run `dart run build_runner build --delete-conflicting-outputs` to generate.

---

## Verification

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All must pass.

---

## Files to create

1. `lib/data/services/rss_news_service.dart`
2. `test/mocks/mock_http_client.dart`
3. `test/unit/rss_news_service_test.dart`
