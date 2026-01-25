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
└── tasks.jsonl               # Task execution log

lib/                          # Flutter application source (to be created)
├── core/                     # Constants, theme, utilities
├── data/                     # Models, repositories, services
├── domain/                   # Business logic (state machine, matchers)
├── presentation/             # Screens, widgets, providers
└── l10n/                     # Localization (if implemented)
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

Run these after implementing to get immediate feedback:

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test.dart

# Analyze code
flutter analyze

# Check formatting
dart format --set-exit-if-changed .
```

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

## Codebase Patterns

_To be updated as patterns emerge during implementation._
