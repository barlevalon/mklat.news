# AGENTS.md - Operational Guide

## Project Overview

mklat.news mobile app - Flutter-based iOS/Android app for Israeli emergency alert tracking.

## Development Environment

Tools are managed via `mise.toml`. Run `mise install` to set up.

**Available tools:**
- Flutter 3.38.7 (stable)
- Dart 3.10.7

**First-time setup:**
```bash
# Install tools defined in mise.toml
mise install

# Verify Flutter is available
flutter --version

# Check environment (Android SDK may need separate setup)
flutter doctor
```

**Android SDK (if needed):**
Android SDK is NOT included in mise.toml. If building for Android:
1. Install Android Studio, OR
2. Install command-line tools manually and run `flutter config --android-sdk /path/to/sdk`
3. Accept licenses: `flutter doctor --android-licenses`

## Directory Structure

```
.agent/
├── specs/                    # Product specifications (source of truth)
│   ├── 00-product-overview.md
│   ├── 01-data-layer.md
│   ├── 02-state-management.md
│   ├── 03-status-screen.md
│   ├── 04-news-screen.md
│   ├── 05-location-management.md
│   ├── 06-error-handling.md
│   └── 07-deferred-features.md
├── IMPLEMENTATION_PLAN.md    # Prioritized task list
├── memories.md               # Persistent learnings
└── tasks/                    # Task specs for implementation phases

lib/                          # Flutter application source
├── core/                     # Constants, theme, utilities
├── data/                     # Models, repositories, services
├── domain/                   # Business logic (state machine, matchers)
├── presentation/             # Screens, widgets, providers
└── l10n/                     # Localization (if implemented)

test/
├── unit/                     # Unit tests for models, services, state machine
├── widget/                   # Widget tests for UI components
├── integration/              # Fixture-based integration tests (no emulator)
├── fixtures/
│   ├── fixture_helper.dart   # Utility to load fixture files
│   └── responses/            # Raw HTTP response captures (.bin + _headers.txt)
└── mocks/                    # Shared mock classes

integration_test/             # Flutter integration tests (requires emulator)
├── app_test.dart             # Critical user flow tests
└── test_fixtures.dart        # Fixture bytes as compile-time Dart constants

tool/
└── generate_test_fixtures.dart  # Script to regenerate test_fixtures.dart
```

## Legacy Web App (Reference Only)

The existing web app code in `src/`, `public/`, etc. is being superseded by the Flutter mobile app.
It remains as reference for business logic patterns but should not be modified.

Key reference files:
- `src/utils/alert-state-machine.js` - Alert state machine logic
- `src/utils/location-matcher.js` - Location matching algorithms
- `src/services/oref.service.js` - OREF API integration patterns
- `src/utils/html-parser.util.js` - Historical alerts HTML parsing
- `src/config/constants.js` - API endpoints, fallback location list (~1,425 locations)

## Build & Run

```bash
# Get dependencies
flutter pub get

# Run on connected device/simulator
flutter run

# Run on specific device
flutter run -d <device_id>

# Build for release
flutter build apk      # Android
flutter build ios      # iOS
```

## Validation

A `Makefile` is available for all validation tasks. **All new work must pass `make check` before committing.**

```bash
# Full pre-push check: format + analyze + unit + integration tests
make check

# All tests (unit + integration)
make test-all

# Unit + widget + fixture-based tests (no emulator needed, fast)
make test-unit

# Integration tests on emulator (requires running emulator)
make test-integration

# Individual commands
flutter test                    # Unit/widget/fixture tests
flutter analyze                 # Static analysis
dart format --set-exit-if-changed .  # Format check
```

### Emulator setup for integration tests

```bash
# Start the headless emulator
make emulator

# Or manually:
ANDROID_AVD_HOME=~/.config/.android/avd \
JAVA_HOME=$(mise where java@temurin-21.0.10+7.0.LTS) \
emulator -avd mklat_test -no-audio -no-window -gpu swiftshader_indirect &
```

AVD name: `mklat_test` (Pixel 6, API 36, x86_64). AVD home: `~/.config/.android/avd/`.

## Operational Notes

### API Headers
OREF APIs require specific headers to avoid blocking:
```
X-Requested-With: XMLHttpRequest
Referer: https://www.oref.org.il/
User-Agent: Mozilla/5.0 ...
```

### RTL Layout
App is Hebrew-first with RTL layout. Ensure:
- `Directionality` widget or `MaterialApp` locale set
- Text alignment respects RTL
- Icons/arrows flip appropriately

### State Machine
Alert state machine runs on PRIMARY location only. Changing primary location resets state to ALL_CLEAR.

### Polling Strategy
- Alerts: Every 2 seconds (foreground only)
- News: Every 30 seconds (foreground only)
- Stop all polling when app backgrounds
- Resume with fresh fetch when app foregrounds

## Testing Strategy

Three tiers of testing, all mandatory for new work:

### 1. Unit/widget tests (`test/unit/`, `test/widget/`)
- Mock at service level, test business logic and widget rendering
- Fast, no emulator needed
- Run with: `flutter test` or `make test-unit`

### 2. Fixture-based integration tests (`test/integration/`)
- Feed **real HTTP response bytes** (captured from live APIs) through the full decode→parse→model pipeline
- Mock at `http.Client` level (NOT our `HttpClient`) to test the real encoding/parsing chain
- Catches encoding bugs, BOM handling, charset issues that mocked unit tests miss
- Fixtures stored as raw binary in `test/fixtures/responses/`
- No emulator needed — runs with `flutter test`
- **When adding new API endpoints**: capture the real response with curl and add to fixtures

### 3. Flutter integration tests (`integration_test/`)
- Full app running on emulator with mock HTTP responses
- Tests critical user flows: launch, add location, swipe to news, status display
- `MklatApp` accepts optional `http.Client` for dependency injection (hexagonal architecture)
- Fixture bytes embedded as Dart constants in `integration_test/test_fixtures.dart`
- Run with: `make test-integration` (requires running emulator)
- **When adding new screens/flows**: add an integration test for the happy path

### Fixture management

```bash
# Regenerate test_fixtures.dart after updating .bin files
make fixtures

# Capture a new API response
curl -s -D test/fixtures/responses/NAME_headers.txt \
  -o test/fixtures/responses/NAME_body.bin \
  'https://...'
```

### Key testing patterns
- Mock `http.Client` (package level), not our `HttpClient` — tests the full encoding pipeline
- Use `http.Response.bytes()` constructor to preserve raw bytes behavior
- Hebrew validation: `RegExp(r'[\u0590-\u05FF]').hasMatch(text)`
- Anti-mojibake check: verify no `×` (U+00D7) in parsed strings
- For `OrefDistrictsService` tests: `SharedPreferences.setMockInitialValues({})`
- Integration tests use `tester.pump(Duration)` not `pumpAndSettle()` (polling timers prevent settling)

## Codebase Patterns

### Hexagonal Architecture
- `MklatApp` accepts optional `http.Client` for dependency injection
- Services accept `HttpClient` wrapper, which accepts `http.Client`
- Test at any seam: mock `http.Client` for integration, mock services for widget tests

### Service Pattern
- Services never throw — catch errors, return safe defaults (empty lists)
- `HttpClient.get()` handles UTF-8 decoding from `bodyBytes` (not `response.body`)
- OREF headers sent only when `useOrefHeaders: true`

### Provider Pattern
- `provider` package (not Riverpod)
- Polling manager delivers data via callbacks to providers
- Providers are `ChangeNotifier` subclasses
