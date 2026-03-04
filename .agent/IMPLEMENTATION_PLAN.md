# Implementation Plan: mklat.news Mobile App

> **Status**: Updated after API validation (2026-03-04)
> **Last Updated**: 2026-03-04

## Overview

This plan breaks down the implementation into phases. Each task should result in one commit. Tasks are ordered by dependency and priority.

### Development approach: Red/Green TDD

Every task follows the red/green cycle: write a failing test first, then implement the minimum code to pass it, then refactor. Do not write production code without a failing test driving it. This applies to all data layer services, state machine logic, models, parsing, and business logic. UI widget tests where practical.

---

## Phase 1: Project Foundation

### 1.1 Flutter Project Setup
- [x] Create new Flutter project with package name `news.mklat.app`
- [x] Configure pubspec.yaml with required dependencies
- [x] Set up folder structure per specs (`lib/core`, `lib/data`, `lib/domain`, `lib/presentation`)
- [x] Configure RTL support and Hebrew locale
- **Spec**: `00-product-overview.md`
- **Acceptance**: Project builds and runs on iOS simulator and Android emulator

### 1.2 Data Models
- [x] Create `Alert` model with `AlertCategory` enum (rockets, uav, clearance, imminent, other)
- [x] Create `OrefLocation` model (name, id, hashId, areaId, areaName, shelterTimeSec)
- [x] Create `NewsItem` model with `NewsSource` enum
- [x] Create `SavedLocation` model (with cached shelterTimeSec)
- [x] Create `AlertState` enum
- **Spec**: `01-data-layer.md`, `02-state-management.md`
- **Acceptance**: Models serialize/deserialize correctly, unit tests pass (TDD)

### 1.3 API Constants
- [x] Create `api_endpoints.dart` with all OREF and RSS URLs
- [x] Create `app_constants.dart` with polling intervals, timeouts
- **Spec**: `01-data-layer.md`
- **Acceptance**: Constants accessible throughout app

---

## Phase 2: Data Layer

### 2.1 OREF Current Alerts Service
- [x] Implement HTTP client with required OREF headers
- [x] Fetch and parse `Alerts.json`
- [x] Handle BOM + `\r\n` empty response (5 bytes)
- [x] Handle empty string response
- [x] Parse JSON object response: extract `id`, `cat`, `title`, `desc`, `data` array
- [x] Normalize to structured result (active location list + metadata)
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service handles all response variants, unit tests pass (TDD)

### 2.2 OREF Alert History Service
- [x] Fetch `AlertsHistory.json` (NOT the legacy HTML endpoint)
- [x] Parse JSON array to `List<Alert>`
- [x] Map `category` field to `AlertCategory` enum (1=rockets, 2=uav, 13=clearance, 14=imminent)
- [x] Parse `alertDate` as Israel-timezone DateTime
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service parses all categories correctly, unit tests pass (TDD)

### 2.3 OREF Districts Service
- [x] Fetch districts JSON, parse to `List<OrefLocation>` (with shelterTimeSec/migun_time)
- [x] Implement fallback to `cities_heb.json` (split pipe-separated labels)
- [ ] Implement hardcoded fallback list (~1,486 locations) — deferred, returns empty list as last resort
- **Spec**: `01-data-layer.md`, `05-location-management.md`
- **Acceptance**: Service returns locations with shelter times, falls back gracefully, unit tests pass (TDD)

### 2.4 RSS News Service
- [x] Implement RSS XML parser
- [x] Fetch and parse all 4 news feeds
- [x] Follow redirects (Maariv returns 308)
- [x] Handle Walla timezone bug
- [x] Normalize to `List<NewsItem>`
- [x] Handle individual feed failures gracefully
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service returns combined news list, handles partial failures, unit tests pass (TDD)

### 2.5 Polling Manager
- [x] Create polling manager for foreground/background lifecycle
- [x] Implement 2-second polling for alerts
- [x] Implement 30-second polling for news
- [x] Start polling on foreground, stop on background
- **Spec**: `01-data-layer.md`
- **Acceptance**: Polling starts/stops correctly with app lifecycle

---

## Phase 3: State Management

### 3.1 Alert State Machine
- [x] Implement `AlertStateMachine` class with all 5 states
- [x] Implement transition logic driven by active alerts + history categories
- [x] Implement WAITING_CLEAR as absence-based state (was in RED_ALERT, alert dropped, no cat 13 yet)
- [x] WAITING_CLEAR has no auto-timeout — persists until clearance or user changes location
- [x] Implement timer tracking (alertStartTime, clearanceTime)
- [x] Implement location matching (exact match on OREF canonical names)
- **Spec**: `02-state-management.md`
- **Acceptance**: State machine transitions correctly through all paths, unit tests pass (TDD). Must cover:
  - Full path: ALL_CLEAR → ALERT_IMMINENT → RED_ALERT → WAITING_CLEAR → JUST_CLEARED → ALL_CLEAR
  - Direct: ALL_CLEAR → RED_ALERT (no prior imminent)
  - Short: ALERT_IMMINENT → JUST_CLEARED (threat resolved without red alert)
  - Re-entry: WAITING_CLEAR → RED_ALERT and JUST_CLEARED → RED_ALERT (new attack)
  - Priority: active alert always wins → RED_ALERT regardless of current state
  - Self-loop: RED_ALERT stays RED_ALERT without resetting alertStartTime
  - Location change resets to ALL_CLEAR from any state

### 3.2 Location State Provider
- [x] Create `LocationProvider` with SavedLocation CRUD
- [x] Implement primary location selection
- [x] Implement persistence to SharedPreferences
- [x] Load saved locations on app start
- **Spec**: `02-state-management.md`, `05-location-management.md`
- **Acceptance**: Locations persist across app restarts, CRUD operations work

### 3.3 Alerts Provider
- [x] Create `AlertsProvider` combining current and historical alerts
- [x] Integrate with polling manager
- [x] Implement filtering by saved locations
- [x] Compute nationwide vs user location counts
- **Spec**: `02-state-management.md`
- **Acceptance**: Provider exposes filtered alerts, updates on poll

### 3.4 News Provider
- [x] Create `NewsProvider` for news items
- [x] Integrate with polling manager
- [x] Sort by publication date
- **Spec**: `02-state-management.md`
- **Acceptance**: Provider exposes sorted news, updates on poll

### 3.5 Connectivity Provider
- [x] Create `ConnectivityProvider` for online/offline status
- [x] Monitor network changes
- [x] Expose isOffline state
- **Spec**: `06-error-handling.md`
- **Acceptance**: Provider correctly reflects network state

---

## Phase 4: UI - Core Components

### 4.1 App Shell & Navigation
- [x] Create app shell with PageView for two screens
- [x] Implement swipe navigation between Status and News
- [x] Add page indicator dots
- **Spec**: `03-status-screen.md`, `04-news-screen.md`
- **Acceptance**: Swipe navigation works, indicator shows current page

### 4.2 Primary Status Card Widget
- [x] Create widget displaying alert state
- [x] Implement all 5 state variants with icons, text, instructions
- [x] Implement elapsed timer display
- [x] Implement visual styling per state (colors, animation)
- **Spec**: `03-status-screen.md`
- **Acceptance**: Widget displays correct state, timer updates every second

### 4.3 Location Selector Button
- [x] Create tappable button showing primary location
- [x] Show "בחר אזור" when no location selected
- [x] Tap opens location management modal
- **Spec**: `03-status-screen.md`, `05-location-management.md`
- **Acceptance**: Button displays location, tap opens modal

### 4.4 Secondary Locations Row
- [x] Create horizontal row of secondary locations
- [x] Show status indicator (colored dot) per location
- [x] Handle scrolling if many locations
- [x] Hide if only one saved location
- **Spec**: `03-status-screen.md`
- **Acceptance**: Row shows secondary locations with correct status indicators

### 4.5 Nationwide Summary Widget
- [x] Create widget showing alert counts
- [x] Display user location count and nationwide count
- [x] Hide when no active alerts
- **Spec**: `03-status-screen.md`
- **Acceptance**: Summary shows during events, hidden otherwise

### 4.6 Alert List Item Widget
- [x] Create widget for single alert in list
- [x] Display type icon, location, time
- [x] Style based on alert type
- **Spec**: `03-status-screen.md`
- **Acceptance**: Widget displays alert data correctly

### 4.7 News List Item Widget
- [x] Create widget for single news item
- [x] Display source icon, headline, description, time
- [x] Tap opens URL in browser
- **Spec**: `04-news-screen.md`
- **Acceptance**: Widget displays news data, tap opens browser

---

## Phase 5: UI - Screens

### 5.1 Status Screen
- [x] Assemble Status Screen with all components
- [x] Integrate with providers
- [x] Implement alerts list with pagination ("load more")
- [ ] Implement pull to refresh (optional) — deferred, polling handles freshness
- **Spec**: `03-status-screen.md`
- **Acceptance**: Screen displays all components, data updates in real-time

### 5.2 News Screen
- [x] Assemble News Screen with header and list
- [x] Integrate with NewsProvider
- [ ] Implement pull to refresh — deferred, polling handles freshness
- **Spec**: `04-news-screen.md`
- **Acceptance**: Screen displays news list, tap opens links

### 5.3 Location Management Modal
- [x] Create bottom sheet/modal for location list
- [x] Display saved locations with primary indicator
- [x] Tap to set primary
- [x] Long press / swipe for edit/delete
- **Spec**: `05-location-management.md`
- **Acceptance**: Modal shows locations, interactions work correctly

### 5.4 Add Location Flow
- [x] Create add location screen/modal
- [x] Implement location search
- [x] Implement custom label input
- [x] Implement "set as primary" checkbox
- [x] Save and close
- **Spec**: `05-location-management.md`
- **Acceptance**: User can search, select, label, and save location

### 5.5 Edit Location Flow
- [x] Create edit location screen/modal
- [x] Allow editing custom label
- [x] Allow delete with confirmation
- **Spec**: `05-location-management.md`
- **Acceptance**: User can edit label and delete location

---

## Phase 5.5: Testing Infrastructure

### 5.5.1 Fixture-Based Integration Tests
- [x] Capture real HTTP response bytes from all OREF and RSS endpoints
- [x] Create fixture helper to load responses as `http.Response.bytes()`
- [x] Write encoding regression tests (UTF-8 without charset, BOM handling)
- [x] Write OREF alerts/history/districts fixture tests
- [x] Write RSS fixture tests for all 4 feeds (Hebrew validation, mojibake checks)
- [x] Fix `OrefLocation.fromCitiesFallback` bug (wrong field names: `value`→`cityAlId`, missing `areaname`)
- **Acceptance**: All fixture tests pass, encoding pipeline verified against real production data

### 5.5.2 Flutter Integration Tests (Emulator)
- [x] Add hexagonal architecture: `MklatApp` accepts optional `http.Client`
- [x] Generate test fixture byte constants for device-side testing
- [x] Implement 4 critical user flow tests:
  - App launch with empty state
  - Add location flow (search, select, set primary, save)
  - Swipe to news screen
  - Status screen with pre-populated location
- [x] Create Makefile with `check`, `test-all`, `test-unit`, `test-integration`, `emulator` targets
- **Acceptance**: All 4 integration tests pass on emulator, `make check` runs full validation

---

## Phase 6: Error Handling & Polish

### 6.1 Offline Banner
- [x] Detect connectivity changes
- [x] Show persistent offline banner (animated, orange, "אין חיבור לאינטרנט")
- [x] Auto-dismiss when connection restored
- **Acceptance**: Banner appears offline, disappears online

### 6.2 Loading States
- [x] Implement initial loading spinner ("טוען...")
- [x] Implement "מתעדכן..." overlay on resume
- [x] Implement offline state ("ממתין לחיבור לאינטרנט...")
- **Acceptance**: Loading states display appropriately

### 6.3 Error States
- [x] Implement error indicator below status card ("שגיאה בטעינת התרעות")
- [x] Implement empty states for no data
- [x] Ensure no stale data shown as current (offline hides cached alerts)
- **Acceptance**: Errors display correct messages, empty states show

### 6.4 App Resume Handling
- [x] Detect app resume from background
- [x] Show "מתעדכן..." overlay
- [x] Fetch fresh data
- [x] Remove overlay when complete (on first successful data callback)
- **Acceptance**: Resume flow works smoothly

---

## Phase 7: Deep Linking & Final Polish

### 7.1 Deep Linking
- Deferred to future phase. See `specs/07-deferred-features.md`.

### 7.2 App Icon & Splash Screen
- [x] Design app icon (red-orange shield with siren, alert waves)
- [x] Generate all platform-specific icon sizes via `flutter_launcher_icons`
- [x] Configure native splash screen via `flutter_native_splash`
- **Acceptance**: Icon and splash display correctly on both platforms

### 7.3 Final Testing & Bug Fixes
- [ ] Test all flows on Android device/emulator
- [ ] Fix any discovered bugs
- [ ] Verify RTL layout throughout
- **Acceptance**: App works correctly

---

## Future Phases (Deferred)

See `specs/07-deferred-features.md` for features to be prioritized later:
- GPS-based location detection
- Multi-language support
- Analytics
- Background fetching
- Family mode
- News filtering
- Dark mode
- Accessibility enhancements

---

## Notes

### API validation (2026-03-04)
- All OREF endpoints confirmed live and functional
- Discovered `AlertsHistory.json` — structured JSON replacement for the 10.5 MB HTML endpoint. Eliminates all HTML regex parsing.
- Districts endpoint returns 1,486 unique locations with `migun_time` (shelter time in seconds)
- `"ניתן לצאת מהמרחב המוגן"` string does NOT appear in real alert data — WAITING_CLEAR state redesigned as absence-based detection
- Maariv RSS returns 308 redirect — HTTP client must follow redirects
- Alert categories: 1=rockets, 2=UAV, 13=ended, 14=imminent
