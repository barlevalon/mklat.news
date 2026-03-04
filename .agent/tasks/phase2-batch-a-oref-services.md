# Phase 2 Batch A: HTTP Client + OREF Services

## Context

Implement the HTTP client foundation and all three OREF API services. These services fetch data from OREF endpoints and return Dart model objects.

Read these files before starting:
- `.agent/specs/01-data-layer.md` — full spec for all endpoints
- `lib/core/api_endpoints.dart` — endpoint URLs
- `lib/core/app_constants.dart` — headers, timeouts, cache keys
- `lib/data/models/alert.dart` — Alert model with `fromOrefActive` and `fromOrefHistory`
- `lib/data/models/oref_location.dart` — OrefLocation model with `fromDistricts` and `fromCitiesFallback`

## Architecture

```
lib/data/services/
├── http_client.dart          # Shared HTTP client wrapper
├── oref_alerts_service.dart  # Current alerts (Alerts.json)
├── oref_history_service.dart # Alert history (AlertsHistory.json)
└── oref_districts_service.dart # Districts/locations
```

All services are plain Dart classes (no Flutter widgets). They take the HTTP client as a constructor dependency for testability.

---

## Task 1: HTTP Client Wrapper

**File:** `lib/data/services/http_client.dart`

A thin wrapper around the `http` package that:
1. Adds OREF-required headers to all requests
2. Handles timeouts
3. Strips UTF-8 BOM from response bodies
4. Provides a clean API for GET requests

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/app_constants.dart';

class HttpClient {
  final http.Client _client;

  HttpClient({http.Client? client}) : _client = client ?? http.Client();

  /// GET request with OREF headers. Returns raw response body as String.
  /// Strips UTF-8 BOM if present.
  /// Throws HttpException on non-2xx status codes.
  /// Throws TimeoutException on timeout.
  Future<String> get(String url, {Map<String, String>? extraHeaders}) async {
    final headers = Map<String, String>.from(AppConstants.orefHeaders);
    if (extraHeaders != null) headers.addAll(extraHeaders);

    final response = await _client
        .get(Uri.parse(url), headers: headers)
        .timeout(Duration(seconds: AppConstants.httpTimeoutSeconds));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'HTTP ${response.statusCode} from $url',
        statusCode: response.statusCode,
      );
    }

    return _stripBom(response.body);
  }

  /// Strip UTF-8 BOM (\xEF\xBB\xBF or \uFEFF) from the start of a string.
  String _stripBom(String input) {
    if (input.startsWith('\uFEFF')) {
      return input.substring(1);
    }
    return input;
  }

  void dispose() {
    _client.close();
  }
}

class HttpException implements Exception {
  final String message;
  final int statusCode;
  HttpException(this.message, {required this.statusCode});
  @override
  String toString() => 'HttpException: $message';
}
```

Key details:
- BOM is `\uFEFF` in Dart strings (the `http` package decodes UTF-8 bytes to String, converting the 3-byte BOM `\xEF\xBB\xBF` to the single codepoint `\uFEFF`)
- Timeout uses `AppConstants.httpTimeoutSeconds` (10s)
- Custom `HttpException` with status code for error handling
- Accepts optional `http.Client` for testing (mock injection)

---

## Task 2: OREF Current Alerts Service

**File:** `lib/data/services/oref_alerts_service.dart`

Fetches and parses the current active alerts from `Alerts.json`.

```dart
import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../models/alert.dart';
import 'http_client.dart';

class OrefAlertsService {
  final HttpClient _httpClient;

  OrefAlertsService(this._httpClient);

  /// Fetch current active alerts.
  /// Returns a list of Alert objects (one per location in the alert).
  /// Returns empty list if no active alerts or on error.
  Future<List<Alert>> fetchCurrentAlerts() async {
    try {
      final body = await _httpClient.get(ApiEndpoints.orefAlerts);
      return _parseAlertsResponse(body);
    } catch (e) {
      // TODO: Log error
      return [];
    }
  }

  /// Parse the Alerts.json response body.
  /// The response is either:
  /// - Empty/whitespace (after BOM strip) = no alerts → return []
  /// - JSON object with {id, cat, title, desc, data: [...]} → return Alert per location
  List<Alert> _parseAlertsResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    try {
      final json = jsonDecode(trimmed);
      if (json is! Map<String, dynamic>) return [];

      final data = json['data'];
      if (data is! List || data.isEmpty) return [];

      return data
          .whereType<String>()
          .map((location) => Alert.fromOrefActive(json, location))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
```

Key details:
- After BOM stripping (done by HttpClient) and trimming, empty string = no alerts
- The response is a single JSON **object** (not array)
- Each entry in `data[]` becomes a separate `Alert` via `Alert.fromOrefActive`
- Never throws — catches all errors, returns `[]`

---

## Task 3: OREF Alert History Service

**File:** `lib/data/services/oref_history_service.dart`

Fetches and parses the alert history from `AlertsHistory.json`.

```dart
import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../models/alert.dart';
import 'http_client.dart';

class OrefHistoryService {
  final HttpClient _httpClient;

  OrefHistoryService(this._httpClient);

  /// Fetch alert history.
  /// Returns a list of Alert objects from the last ~1 hour of events.
  /// Returns empty list on error.
  Future<List<Alert>> fetchAlertHistory() async {
    try {
      final body = await _httpClient.get(ApiEndpoints.orefHistory);
      return _parseHistoryResponse(body);
    } catch (e) {
      return [];
    }
  }

  /// Parse the AlertsHistory.json response body.
  /// Response is a JSON array of objects: [{alertDate, title, data, category}, ...]
  List<Alert> _parseHistoryResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];

      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => Alert.fromOrefHistory(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
```

Key details:
- Response is a JSON **array** (unlike current alerts which is an object)
- Each entry maps directly via `Alert.fromOrefHistory`
- `alertDate` is in Israel timezone format `"YYYY-MM-DD HH:MM:SS"` — `DateTime.parse` handles this (treated as local time for now; timezone correction is a future improvement)
- Never throws

---

## Task 4: OREF Districts Service

**File:** `lib/data/services/oref_districts_service.dart`

Fetches and caches the OREF districts (location list with shelter times). Implements the three-tier fallback chain: Districts API → cities_heb.json → hardcoded.

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api_endpoints.dart';
import '../../core/app_constants.dart';
import '../models/oref_location.dart';
import 'http_client.dart';

class OrefDistrictsService {
  final HttpClient _httpClient;

  OrefDistrictsService(this._httpClient);

  /// Fetch districts with fallback chain.
  /// 1. Try Districts API (has migun_time)
  /// 2. Fallback to cities_heb.json (no migun_time)
  /// 3. Return empty list as last resort (hardcoded fallback deferred)
  Future<List<OrefLocation>> fetchDistricts() async {
    // Try cache first
    final cached = await _loadFromCache();
    if (cached != null && cached.isNotEmpty) return cached;

    // Try primary: GetDistricts.aspx
    try {
      final body = await _httpClient.get(ApiEndpoints.orefDistricts);
      final locations = _parseDistrictsResponse(body);
      if (locations.isNotEmpty) {
        await _saveToCache(locations);
        return locations;
      }
    } catch (e) {
      // Fall through to fallback
    }

    // Fallback: cities_heb.json
    try {
      final body = await _httpClient.get(ApiEndpoints.orefCitiesFallback);
      final locations = _parseCitiesFallbackResponse(body);
      if (locations.isNotEmpty) {
        await _saveToCache(locations);
        return locations;
      }
    } catch (e) {
      // Fall through
    }

    // Ultimate fallback: empty list (hardcoded list is deferred)
    return [];
  }

  List<OrefLocation> _parseDistrictsResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];
    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];
      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => OrefLocation.fromDistricts(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }

  List<OrefLocation> _parseCitiesFallbackResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];
    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];
      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => OrefLocation.fromCitiesFallback(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Load cached districts from SharedPreferences.
  Future<List<OrefLocation>?> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestampStr = prefs.getString(AppConstants.districtsCacheTimestampKey);
      if (timestampStr == null) return null;

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      if (age.inHours >= AppConstants.districtsCacheDurationHours) return null;

      final jsonStr = prefs.getString(AppConstants.districtsCacheKey);
      if (jsonStr == null) return null;

      final list = jsonDecode(jsonStr) as List;
      return list
          .whereType<Map<String, dynamic>>()
          .map((e) => OrefLocation.fromJson(e))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Save districts to SharedPreferences cache.
  Future<void> _saveToCache(List<OrefLocation> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(locations.map((l) => l.toJson()).toList());
      await prefs.setString(AppConstants.districtsCacheKey, jsonStr);
      await prefs.setString(
        AppConstants.districtsCacheTimestampKey,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      // Cache failure is non-fatal
    }
  }
}
```

Key details:
- Three-tier fallback: Districts → cities_heb → empty list
- Cache in SharedPreferences with 24-hour TTL (`districtsCacheDurationHours`)
- Uses `OrefLocation.fromJson` for cache deserialization (internal format)
- Uses `OrefLocation.fromDistricts` and `OrefLocation.fromCitiesFallback` for API responses
- Never throws

---

## Task 5: Unit Tests

Create test files with mock HTTP responses. Use `mockito` to mock `http.Client`.

### `test/unit/http_client_test.dart`
Test:
- BOM stripping (`\uFEFF` prefix removed)
- Normal response returned as-is
- HttpException thrown on non-2xx status
- Timeout behavior (use a delayed mock)
- OREF headers are sent

### `test/unit/oref_alerts_service_test.dart`
Test:
- Empty response (BOM + whitespace) returns `[]`
- Valid alert response returns correct list of Alert objects
- Multiple locations in `data[]` produce multiple Alerts
- Invalid JSON returns `[]`
- HTTP error returns `[]`
- Response with `data` as empty array returns `[]`

### `test/unit/oref_history_service_test.dart`
Test:
- Valid history response returns correct list of Alerts
- Empty response returns `[]`
- Invalid JSON returns `[]`
- HTTP error returns `[]`
- Entries with different categories are mapped correctly

### `test/unit/oref_districts_service_test.dart`
Test:
- Valid Districts response returns correct list of OrefLocation
- Fallback to cities_heb.json when Districts fails
- Cache hit returns cached data
- Cache miss (expired) triggers fresh fetch
- Both endpoints fail returns `[]`

**Important for mocking**: Create a mock HTTP client helper. Use `mockito` with `@GenerateMocks`. The mock setup pattern:

```dart
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([http.Client])
import 'oref_alerts_service_test.mocks.dart';
```

After creating test files with `@GenerateMocks`, run `dart run build_runner build --delete-conflicting-outputs` to generate mock files before running tests.

---

## Verification

After all changes:
```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

All must pass with zero errors.

---

## Files to create

1. `lib/data/services/http_client.dart`
2. `lib/data/services/oref_alerts_service.dart`
3. `lib/data/services/oref_history_service.dart`
4. `lib/data/services/oref_districts_service.dart`
5. `test/unit/http_client_test.dart`
6. `test/unit/oref_alerts_service_test.dart`
7. `test/unit/oref_history_service_test.dart`
8. `test/unit/oref_districts_service_test.dart`
