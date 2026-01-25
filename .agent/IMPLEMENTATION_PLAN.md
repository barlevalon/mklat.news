# Implementation Plan: mklat.news Mobile App

> **Status**: Initial plan generated from specs
> **Last Updated**: 2026-01-24

## Overview

This plan breaks down the implementation into phases. Each task should result in one commit. Tasks are ordered by dependency and priority.

---

## Phase 1: Project Foundation

### 1.1 Flutter Project Setup
- [ ] Create new Flutter project with package name `news.mklat.app`
- [ ] Configure pubspec.yaml with required dependencies
- [ ] Set up folder structure per specs (`lib/core`, `lib/data`, `lib/domain`, `lib/presentation`)
- [ ] Configure RTL support and Hebrew locale
- **Spec**: `00-product-overview.md`
- **Acceptance**: Project builds and runs on iOS simulator and Android emulator

### 1.2 Data Models
- [ ] Create `Alert` model with `AlertType` enum
- [ ] Create `NewsItem` model with `NewsSource` enum
- [ ] Create `SavedLocation` model
- [ ] Create `AlertState` enum
- **Spec**: `01-data-layer.md`, `02-state-management.md`
- **Acceptance**: Models serialize/deserialize correctly, unit tests pass

### 1.3 API Constants
- [ ] Create `api_endpoints.dart` with all OREF and RSS URLs
- [ ] Create `app_constants.dart` with polling intervals, timeouts
- **Spec**: `01-data-layer.md`
- **Acceptance**: Constants accessible throughout app

---

## Phase 2: Data Layer

### 2.1 OREF Current Alerts Service
- [ ] Implement HTTP client with required headers
- [ ] Fetch and parse current alerts JSON
- [ ] Handle all response format variants (empty, array of strings, array of objects)
- [ ] Normalize to `List<Alert>`
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service returns normalized alerts, handles empty responses, unit tests pass

### 2.2 OREF Historical Alerts Service
- [ ] Fetch historical alerts HTML
- [ ] Parse HTML to extract alert data
- [ ] Extract time, location, description, alert type
- [ ] Identify clearance messages
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service parses HTML correctly, extracts all fields, unit tests pass

### 2.3 OREF Districts Service
- [ ] Fetch districts list JSON
- [ ] Parse to `List<String>` of location names
- [ ] Implement fallback to backup URL
- [ ] Implement hardcoded fallback list
- **Spec**: `01-data-layer.md`, `05-location-management.md`
- **Acceptance**: Service returns location list, falls back gracefully, unit tests pass

### 2.4 RSS News Service
- [ ] Implement RSS XML parser
- [ ] Fetch and parse all 4 news feeds
- [ ] Normalize to `List<NewsItem>`
- [ ] Handle individual feed failures gracefully
- **Spec**: `01-data-layer.md`
- **Acceptance**: Service returns combined news list, handles partial failures, unit tests pass

### 2.5 Polling Manager
- [ ] Create polling manager for foreground/background lifecycle
- [ ] Implement 2-second polling for alerts
- [ ] Implement 30-second polling for news
- [ ] Start polling on foreground, stop on background
- **Spec**: `01-data-layer.md`
- **Acceptance**: Polling starts/stops correctly with app lifecycle

---

## Phase 3: State Management

### 3.1 Alert State Machine
- [ ] Implement `AlertStateMachine` class with all states
- [ ] Implement state transition logic
- [ ] Implement timer tracking (alertStartTime, clearanceTime)
- [ ] Implement location matching for alerts
- **Spec**: `02-state-management.md`
- **Acceptance**: State machine transitions correctly through all states, unit tests pass

### 3.2 Location State Provider
- [ ] Create `LocationProvider` with SavedLocation CRUD
- [ ] Implement primary location selection
- [ ] Implement persistence to SharedPreferences
- [ ] Load saved locations on app start
- **Spec**: `02-state-management.md`, `05-location-management.md`
- **Acceptance**: Locations persist across app restarts, CRUD operations work

### 3.3 Alerts Provider
- [ ] Create `AlertsProvider` combining current and historical alerts
- [ ] Integrate with polling manager
- [ ] Implement filtering by saved locations
- [ ] Compute nationwide vs user location counts
- **Spec**: `02-state-management.md`
- **Acceptance**: Provider exposes filtered alerts, updates on poll

### 3.4 News Provider
- [ ] Create `NewsProvider` for news items
- [ ] Integrate with polling manager
- [ ] Sort by publication date
- **Spec**: `02-state-management.md`
- **Acceptance**: Provider exposes sorted news, updates on poll

### 3.5 Connectivity Provider
- [ ] Create `ConnectivityProvider` for online/offline status
- [ ] Monitor network changes
- [ ] Expose isOffline state
- **Spec**: `06-error-handling.md`
- **Acceptance**: Provider correctly reflects network state

---

## Phase 4: UI - Core Components

### 4.1 App Shell & Navigation
- [ ] Create app shell with PageView for two screens
- [ ] Implement swipe navigation between Status and News
- [ ] Add page indicator dots
- **Spec**: `03-status-screen.md`, `04-news-screen.md`
- **Acceptance**: Swipe navigation works, indicator shows current page

### 4.2 Primary Status Card Widget
- [ ] Create widget displaying alert state
- [ ] Implement all 5 state variants with icons, text, instructions
- [ ] Implement elapsed timer display
- [ ] Implement visual styling per state (colors, animation)
- **Spec**: `03-status-screen.md`
- **Acceptance**: Widget displays correct state, timer updates every second

### 4.3 Location Selector Button
- [ ] Create tappable button showing primary location
- [ ] Show "בחר אזור" when no location selected
- [ ] Tap opens location management modal
- **Spec**: `03-status-screen.md`, `05-location-management.md`
- **Acceptance**: Button displays location, tap opens modal

### 4.4 Secondary Locations Row
- [ ] Create horizontal row of secondary locations
- [ ] Show status indicator (colored dot) per location
- [ ] Handle scrolling if many locations
- [ ] Hide if only one saved location
- **Spec**: `03-status-screen.md`
- **Acceptance**: Row shows secondary locations with correct status indicators

### 4.5 Nationwide Summary Widget
- [ ] Create widget showing alert counts
- [ ] Display user location count and nationwide count
- [ ] Hide when no active alerts
- **Spec**: `03-status-screen.md`
- **Acceptance**: Summary shows during events, hidden otherwise

### 4.6 Alert List Item Widget
- [ ] Create widget for single alert in list
- [ ] Display type icon, location, time
- [ ] Style based on alert type
- **Spec**: `03-status-screen.md`
- **Acceptance**: Widget displays alert data correctly

### 4.7 News List Item Widget
- [ ] Create widget for single news item
- [ ] Display source icon, headline, description, time
- [ ] Tap opens URL in browser
- **Spec**: `04-news-screen.md`
- **Acceptance**: Widget displays news data, tap opens browser

---

## Phase 5: UI - Screens

### 5.1 Status Screen
- [ ] Assemble Status Screen with all components
- [ ] Integrate with providers
- [ ] Implement alerts list with pagination ("load more")
- [ ] Implement pull to refresh (optional)
- **Spec**: `03-status-screen.md`
- **Acceptance**: Screen displays all components, data updates in real-time

### 5.2 News Screen
- [ ] Assemble News Screen with header and list
- [ ] Integrate with NewsProvider
- [ ] Implement pull to refresh
- **Spec**: `04-news-screen.md`
- **Acceptance**: Screen displays news list, tap opens links

### 5.3 Location Management Modal
- [ ] Create bottom sheet/modal for location list
- [ ] Display saved locations with primary indicator
- [ ] Tap to set primary
- [ ] Long press / swipe for edit/delete
- **Spec**: `05-location-management.md`
- **Acceptance**: Modal shows locations, interactions work correctly

### 5.4 Add Location Flow
- [ ] Create add location screen/modal
- [ ] Implement location search
- [ ] Implement custom label input
- [ ] Implement "set as primary" checkbox
- [ ] Save and close
- **Spec**: `05-location-management.md`
- **Acceptance**: User can search, select, label, and save location

### 5.5 Edit Location Flow
- [ ] Create edit location screen/modal
- [ ] Allow editing custom label
- [ ] Allow delete with confirmation
- **Spec**: `05-location-management.md`
- **Acceptance**: User can edit label and delete location

---

## Phase 6: Error Handling & Polish

### 6.1 Offline Banner
- [ ] Create offline banner component
- [ ] Show when connectivity lost
- [ ] Auto-dismiss on recovery
- **Spec**: `06-error-handling.md`
- **Acceptance**: Banner appears offline, disappears online

### 6.2 Loading States
- [ ] Implement initial loading spinner
- [ ] Implement "מתעדכן..." overlay on resume
- [ ] Implement load more indicator
- **Spec**: `06-error-handling.md`
- **Acceptance**: Loading states display appropriately

### 6.3 Error States
- [ ] Implement error messages for API failures
- [ ] Implement empty states for no data
- [ ] Ensure no stale data shown as current
- **Spec**: `06-error-handling.md`
- **Acceptance**: Errors display correct messages, empty states show

### 6.4 App Resume Handling
- [ ] Detect app resume from background
- [ ] Show "מתעדכן..." overlay
- [ ] Fetch fresh data
- [ ] Remove overlay when complete
- **Spec**: `06-error-handling.md`
- **Acceptance**: Resume flow works smoothly

---

## Phase 7: Deep Linking & Final Polish

### 7.1 Deep Linking
- [ ] Configure deep link handling for `mklat://` scheme
- [ ] Handle `mklat://location/{name}` to pre-select location
- [ ] Test on both platforms
- **Spec**: `05-location-management.md`
- **Acceptance**: Deep links open app and pre-select location

### 7.2 App Icon & Splash Screen
- [ ] Design and add app icon (all required sizes)
- [ ] Configure splash screen
- **Spec**: `00-product-overview.md`
- **Acceptance**: Icon and splash display correctly on both platforms

### 7.3 Final Testing & Bug Fixes
- [ ] Test all flows on iOS device/simulator
- [ ] Test all flows on Android device/emulator
- [ ] Fix any discovered bugs
- [ ] Verify RTL layout throughout
- **Acceptance**: App works correctly on both platforms

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

_This section is for Ralph to document discoveries, blockers, and learnings during implementation._
