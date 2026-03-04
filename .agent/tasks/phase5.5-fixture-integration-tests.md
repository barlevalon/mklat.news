# Phase 5.5: Fixture-Based Integration Tests

## Goal

Create integration tests that feed **real HTTP response bytes** (captured from live OREF and RSS endpoints) through the **full decode→parse→model pipeline**. These tests mock at the `http.Client` level (NOT our `HttpClient`), ensuring the entire chain from raw bytes to domain models is tested with production-realistic data.

## Why

Unit tests that mock our `HttpClient` return pre-decoded Dart strings, completely bypassing the encoding pipeline. This missed a critical encoding bug: Dart's `http` package defaults to Latin-1 when Content-Type omits charset, which garbled Hebrew text from OREF and Ynet. Fixture-based tests would have caught this.

## Fixtures Available

Real responses captured via curl on 2026-03-04, stored in `test/fixtures/responses/`:

| File | Content-Type | Charset? | Notes |
|---|---|---|---|
| `oref_alerts_body.bin` / `_headers.txt` | `application/json` | **No** | 5 bytes: BOM + CRLF (no active alerts) |
| `oref_history_body.bin` / `_headers.txt` | `application/json` | **No** | ~3.7KB, Hebrew UTF-8, no charset |
| `oref_districts_body.bin` / `_headers.txt` | `application/json; charset=UTF8` | Yes (non-standard "UTF8") | ~258KB, full districts list |
| `oref_cities_body.bin` / `_headers.txt` | `application/json` | **No** | ~401KB, Unicode escapes in JSON |
| `rss_ynet_body.bin` / `_headers.txt` | `application/xml` | **No** | ~19KB, Hebrew in UTF-8 bytes |
| `rss_maariv_body.bin` / `_headers.txt` | `application/xml; charset=utf-8` | Yes | ~22KB (after redirect follow) |
| `rss_walla_body.bin` / `_headers.txt` | `text/xml; charset=utf-8` | Yes | ~72KB |
| `rss_haaretz_body.bin` / `_headers.txt` | `text/xml;charset=UTF-8` | Yes | ~156KB |

## Bug to Fix FIRST

**`OrefLocation.fromCitiesFallback` uses wrong field names.** The real `cities_heb.json` API response has:
- `cityAlId` (NOT `value`) for the hash identifier
- No `areaname` field at all
- `label` field contains `"name | area"` with pipe separator (correct)

Current code at `lib/data/models/oref_location.dart:56-67`:
```dart
factory OrefLocation.fromCitiesFallback(Map<String, dynamic> json) {
  final label = json['label'].toString();
  final hebrewName = label.split('|').first;
  return OrefLocation(
    name: hebrewName,
    id: json['id'].toString(),
    hashId: json['value'] as String,        // BUG: should be 'cityAlId'
    areaId: json['areaid'] as int,
    areaName: json['areaname'] as String,    // BUG: field doesn't exist
    shelterTimeSec: null,
  );
}
```

Fix: use `cityAlId` for hashId, extract area name from label (text after `|`), handle entries without `|`.

Real entry example:
```json
{"areaid": 1, "cityAlId": "124FC5752F86660B7458D50DCE51AE40", "id": "10", "label": "אזור תעשייה שחורת", "rashut": null, "color": "R"}
{"areaid": 5, "cityAlId": "6657AD46BF8FA430B022FF282B7A804B", "id": "511", "label": "אבו גוש | אזור שפלת יהודה", "rashut": null, "color": "R"}
```

## Implementation

### 1. Fix `OrefLocation.fromCitiesFallback` (`lib/data/models/oref_location.dart`)

```dart
factory OrefLocation.fromCitiesFallback(Map<String, dynamic> json) {
  final label = json['label'].toString();
  final parts = label.split('|');
  final hebrewName = parts.first.trim();
  final areaName = parts.length > 1 ? parts[1].trim() : '';
  return OrefLocation(
    name: hebrewName,
    id: json['id'].toString(),
    hashId: json['cityAlId'] as String,
    areaId: json['areaid'] as int,
    areaName: areaName,
    shelterTimeSec: null,
  );
}
```

### 2. Create fixture helper (`test/fixtures/fixture_helper.dart`)

A utility that:
- Loads a fixture file as raw bytes from `test/fixtures/responses/`
- Parses the corresponding headers file to extract Content-Type
- Returns an `http.Response.bytes()` with the real status code, headers, and body bytes

```dart
import 'dart:io';
import 'package:http/http.dart' as http;

class FixtureHelper {
  /// Load a fixture response with real bytes and headers.
  /// [name] is the base name, e.g., 'oref_alerts' loads oref_alerts_body.bin and oref_alerts_headers.txt
  static Future<http.Response> loadResponse(String name, {int statusCode = 200}) async {
    final fixtureDir = '${Directory.current.path}/test/fixtures/responses';
    final bodyBytes = await File('$fixtureDir/${name}_body.bin').readAsBytes();
    final headersFile = File('$fixtureDir/${name}_headers.txt');
    final headers = <String, String>{};
    
    if (await headersFile.exists()) {
      final lines = await headersFile.readAsLines();
      for (final line in lines) {
        final colonIndex = line.indexOf(':');
        if (colonIndex > 0) {
          final key = line.substring(0, colonIndex).trim().toLowerCase();
          final value = line.substring(colonIndex + 1).trim();
          headers[key] = value;
        }
      }
    }
    
    return http.Response.bytes(
      bodyBytes,
      statusCode,
      headers: headers,
    );
  }
}
```

### 3. Create test files

#### `test/integration/oref_alerts_fixture_test.dart`

Test `HttpClient` + `OrefAlertsService` with real fixture bytes:

- **Empty alerts (BOM + CRLF)**: Load `oref_alerts` fixture → mock `http.Client` to return it → create real `HttpClient` wrapping mock → create `OrefAlertsService` → call `fetchCurrentAlerts()` → expect empty list (BOM stripped, whitespace-only body handled)
- **Verify BOM is properly stripped**: Feed the raw bytes through `HttpClient.get()` directly → verify returned string doesn't start with `\uFEFF`

#### `test/integration/oref_history_fixture_test.dart`

Test `HttpClient` + `OrefHistoryService` with real fixture bytes:

- Load `oref_history` fixture (no charset in Content-Type, Hebrew in UTF-8)
- Mock `http.Client` → real `HttpClient` → `OrefHistoryService`
- `fetchAlertHistory()` → verify:
  - Returns non-empty list
  - First alert has Hebrew `title` field (contains Hebrew characters, not mojibake)
  - First alert has Hebrew `location` field
  - `time` is parsed correctly (from `alertDate` field)
  - `category` is a valid integer
  - Verify a known Hebrew string from the fixture is present (look at the actual data to find one)

#### `test/integration/oref_districts_fixture_test.dart`

Test `HttpClient` + `OrefDistrictsService` with real fixture bytes:

**Districts (primary source):**
- Load `oref_districts` fixture (charset=UTF8, non-standard)
- Verify returns 1000+ locations
- Verify Hebrew names are intact (find a known name like "תל אביב" or "ירושלים" in the parsed results)
- Verify `shelterTimeSec` is populated on entries that have it
- Verify `areaName` is populated with Hebrew

**Cities fallback:**
- Load `oref_cities` fixture
- Verify returns 1350 entries
- Verify Hebrew names parsed correctly
- Verify pipe separator handled (e.g., "אבו גוש" extracted from "אבו גוש | אזור שפלת יהודה")
- Verify entries WITHOUT pipe work (e.g., "אזור תעשייה שחורת" → name = "אזור תעשייה שחורת", areaName = "")

**Cache behavior:**
- For districts tests, use `SharedPreferences.setMockInitialValues({})` so cache is empty and it fetches from network

#### `test/integration/rss_news_fixture_test.dart`

Test `HttpClient` + `RssNewsService` with real fixture bytes:

For each feed (ynet, walla, haaretz, maariv):
- Load fixture → mock `http.Client` to return correct fixture per URL
- Call `fetchAllNews()` or `_fetchFeed()` individually
- Verify:
  - Returns non-empty list of `NewsItem`s
  - Titles contain Hebrew text (check with RegExp for Hebrew Unicode range `[\u0590-\u05FF]`)
  - Links are valid URLs (start with http)
  - `pubDate` is a reasonable DateTime (not the fallback `DateTime.now()`)
  - `source` is set correctly
  - No mojibake (no Latin-1 artifacts like `×` characters which indicate encoding failure)

**Combined test:**
- Mock all 4 feeds with their fixtures
- Call `fetchAllNews()`
- Verify items from multiple sources are present
- Verify sorted by pubDate descending

#### `test/integration/encoding_regression_test.dart`

Focused regression tests for the specific encoding bug:

- **The original bug scenario**: Create `http.Response.bytes()` with UTF-8 Hebrew bytes but Content-Type `application/json` (no charset). Feed through `HttpClient.get()`. Verify Hebrew comes through correctly. This WOULD HAVE FAILED before the encoding fix.
- **BOM handling**: Feed bytes starting with EF BB BF through `HttpClient.get()`. Verify BOM stripped.
- **Non-standard charset=UTF8**: Feed with Content-Type `application/json; charset=UTF8`. Verify works.

### 4. Update existing unit tests for `fromCitiesFallback`

The test file `test/unit/oref_location_test.dart` likely has tests for `fromCitiesFallback` using wrong field names. Update those tests to match the real API format (`cityAlId`, no `areaname`).

## Directory structure

```
test/
├── fixtures/
│   ├── fixture_helper.dart
│   └── responses/          # Already exists with captured .bin and .txt files
├── integration/
│   ├── encoding_regression_test.dart
│   ├── oref_alerts_fixture_test.dart
│   ├── oref_history_fixture_test.dart
│   ├── oref_districts_fixture_test.dart
│   └── rss_news_fixture_test.dart
├── unit/                    # Existing
├── widget/                  # Existing
└── mocks/                   # Existing
```

## Verification

Run all tests after implementation:
```bash
flutter test
```

All tests must pass, including both the new integration tests and the existing 231 unit/widget tests.

Also run:
```bash
flutter analyze
dart format --set-exit-if-changed .
```

## Important Notes

- Do NOT create mocks of our `HttpClient` class. The whole point is to test through it.
- DO mock `http.Client` (the package-level client) to return fixture bytes.
- Use `http.Response.bytes()` constructor (not `http.Response()`) to preserve the raw-bytes-to-string decoding behavior.
- For `OrefDistrictsService` tests, you need `SharedPreferences.setMockInitialValues({})` in setUp.
- Hebrew character validation: use `RegExp(r'[\u0590-\u05FF]')` to verify Hebrew is present.
- Anti-mojibake check: verify strings do NOT contain `×` (U+00D7) which is a telltale Latin-1-decoded-as-UTF-8 artifact.
- The fixture files are binary — read them with `File.readAsBytes()`, never as string.
- When setting up mock `http.Client` for services, match the URL to return the right fixture. Use `when(mockClient.get(argThat(predicate matching URL), ...))`.
