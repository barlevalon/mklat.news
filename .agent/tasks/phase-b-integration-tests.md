# Phase B: Flutter integration_test with Mock Services

## Goal

Add Flutter `integration_test` flows that run the full app on an emulator with injected mock HTTP responses (using the same fixture data from Phase 5.5). Tests verify critical user flows end-to-end.

## Architecture Change

Make `MklatApp` accept an optional `http.Client` dependency so integration tests can inject a mock.

### `lib/main.dart` changes

Add an optional `httpClient` parameter to `MklatApp`:

```dart
import 'package:http/http.dart' as http;

class MklatApp extends StatefulWidget {
  final http.Client? httpClient;
  const MklatApp({super.key, this.httpClient});

  @override
  State<MklatApp> createState() => _MklatAppState();
}
```

In `_initializeServices()`, use the injected client if provided:

```dart
void _initializeServices() {
  _httpClient = HttpClient(client: widget.httpClient);
  // ... rest unchanged
}
```

The `HttpClient` constructor already accepts `http.Client? client` and defaults to creating a real one, so this is a one-line change.

Production `main()` stays unchanged: `runApp(const MklatApp())` — no client passed, real HTTP used.

## Dependencies

Add `integration_test` to `pubspec.yaml` under `dev_dependencies`:

```yaml
dev_dependencies:
  # ... existing
  integration_test:
    sdk: flutter
```

Also need `mockito` (already present) for the mock `http.Client`.

## Test Files

### `integration_test/app_test.dart`

The main integration test file. Uses a mock `http.Client` that returns fixture data.

**Setup:**
- Create a mock `http.Client` (using Mockito's `@GenerateMocks`)
- Configure it to return fixture responses based on URL matching:
  - URLs containing `Alerts.json` → `oref_alerts` fixture (empty, BOM+CRLF)
  - URLs containing `AlertsHistory.json` → `oref_history` fixture
  - URLs containing `GetDistricts.aspx` → `oref_districts` fixture
  - URLs containing `cities_heb.json` → `oref_cities` fixture
  - URLs containing `ynet` → `rss_ynet` fixture
  - URLs containing `maariv` → `rss_maariv` fixture
  - URLs containing `walla` → `rss_walla` fixture
  - URLs containing `haaretz` → `rss_haaretz` fixture
- Load fixture bytes using `File` reads (same fixture files from `test/fixtures/responses/`)
- Pass mock client to `MklatApp(httpClient: mockClient)`

**Test flows:**

#### 1. `testWidgets('app launches with empty state')`
- Pump `MklatApp` with mock client
- Wait for frames to settle (use `pumpAndSettle` with reasonable timeout)
- Verify: "בחר אזור" text is visible (location selector shows placeholder)
- Verify: "הוסף מיקום כדי לראות התרעות" is visible (empty state message)
- Verify: Page indicator dots are visible (2 pages)

#### 2. `testWidgets('add location flow')`
- Launch app with mock client
- Tap the location selector button (find by "בחר אזור" text)
- Verify location management modal opens with "המיקומים שלי"
- Tap the add button (Icons.add)
- Verify "הוסף מיקום" screen appears
- Wait for districts to load (the mock will serve them)
- Type "אבו גוש" in the search field (find by hint "חיפוש...")
- Verify "אבו גוש" appears in filtered list
- Tap "אבו גוש" list item to select it
- Verify checkmark (Icons.check) appears
- Check the "הגדר כמיקום ראשי" checkbox
- Tap "שמור" button
- Verify we're back on status screen
- Verify "אבו גוש" now appears in the location selector (instead of "בחר אזור")
- Verify status shows "הכל תקין" (all clear, since mock alerts are empty)

#### 3. `testWidgets('swipe to news screen')`
- Launch app with mock client
- Wait for settle
- Swipe left on the PageView to go to news screen
- Verify "מבזקי חדשות" header is visible
- Verify news items appear (at least one item from the fixture data)
- Verify items have Hebrew text (find by Hebrew regex pattern)

#### 4. `testWidgets('status screen shows all clear with location')`
- Launch app with mock client
- Pre-populate SharedPreferences with a saved location (use `SharedPreferences.setMockInitialValues`)
- Wait for settle
- Verify location name appears in selector
- Verify "הכל תקין" is displayed (no active alerts in fixture)

## Important Implementation Notes

1. **File paths in integration tests**: Integration tests run on the device/emulator, NOT on the host. Fixture files from `test/fixtures/responses/` are NOT available on the device filesystem. You MUST load fixture data differently:
   - Option A: Embed fixture data as Dart `List<int>` constants (generated from the .bin files)
   - Option B: Use `rootBundle` with assets
   - **Best option**: Create a `integration_test/test_fixtures.dart` file that contains the fixture bytes as compile-time constants. Generate this by reading the .bin files and writing them as `const List<int>` literals.

2. **SharedPreferences in integration tests**: Use `SharedPreferences.setMockInitialValues({})` before launching the app to ensure a clean state.

3. **Timing**: The app starts polling immediately. With mock HTTP, responses are instant, but use `pumpAndSettle()` with a timeout to let async operations complete. If `pumpAndSettle` times out (because of repeating timers from polling), use `pump(Duration(seconds: 2))` instead.

4. **Polling timers**: The polling manager creates repeating timers (2s for alerts, 30s for news). `pumpAndSettle()` will wait forever if timers keep firing. Solutions:
   - Use `tester.pump(Duration(seconds: N))` instead of `pumpAndSettle()` for steps after app launch
   - OR: Allow `pumpAndSettle()` timeout to be short and catch the timeout

5. **RTL layout**: The app wraps in `Directionality(textDirection: TextDirection.rtl)`. Swipe gestures need to account for RTL — swiping "left" in RTL means dragging right-to-left (same physical direction).

6. **`@GenerateMocks`**: Need to generate mocks. Add `@GenerateMocks([http.Client])` and run `dart run build_runner build`.

7. **Running integration tests**:
   ```bash
   flutter test integration_test/app_test.dart
   ```
   This runs on a connected device/emulator. For headless: requires an emulator.

## File Structure

```
integration_test/
├── app_test.dart              # Main integration test
├── app_test.mocks.dart        # Generated mock (from build_runner)
└── test_fixtures.dart         # Fixture bytes as Dart constants
```

## Generating test_fixtures.dart

Create a script or manually generate `integration_test/test_fixtures.dart` that looks like:

```dart
import 'package:http/http.dart' as http;

class TestFixtures {
  static http.Response get orefAlerts => http.Response.bytes(
    _orefAlertsBytes, 200,
    headers: {'content-type': 'application/json'},
  );

  static http.Response get orefHistory => http.Response.bytes(
    _orefHistoryBytes, 200,
    headers: {'content-type': 'application/json'},
  );

  // ... etc for each fixture

  static const _orefAlertsBytes = <int>[0xEF, 0xBB, 0xBF, 0x0D, 0x0A];
  // ... generated from .bin files
}
```

For large fixtures (districts is 258KB, haaretz RSS is 156KB), the generated file will be big but that's fine for test code.

**To generate the byte constants**, write a small Dart script:
```dart
// tool/generate_test_fixtures.dart
import 'dart:io';
void main() {
  final fixtures = ['oref_alerts', 'oref_history', 'oref_districts', 'oref_cities',
                    'rss_ynet', 'rss_maariv', 'rss_walla', 'rss_haaretz'];
  // Read each .bin file, output as Dart const list
  // Read each _headers.txt, extract content-type
  // Write to integration_test/test_fixtures.dart
}
```

Run this script before the integration tests. Or just generate the file once and commit it.

## Verification

After implementation, run:
```bash
# Unit/widget/integration tests (without emulator)
flutter test

# Integration tests (requires emulator or device)
# First ensure emulator is running, then:
flutter test integration_test/app_test.dart
```

All existing 280 tests must still pass. The new integration tests should pass on a connected emulator.

Also run:
```bash
flutter analyze
dart format --set-exit-if-changed .
```
