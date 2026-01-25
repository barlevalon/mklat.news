# State Management Specification

## Overview

The app manages three primary state domains:
1. **Alert State**: The current alert status for the primary location
2. **Location State**: User's saved locations and primary selection
3. **Data State**: Fetched alerts, news, and loading/error states

## Alert State Machine

The alert state machine tracks the lifecycle of an alert event for the user's primary location.

### States

```
┌─────────────┐
│  ALL_CLEAR  │ ← Default state, no active alerts
└──────┬──────┘
       │ Alert detected for primary location
       ▼
┌─────────────────┐
│ ALERT_IMMINENT  │ ← "בדקות הקרובות צפויות התרעות"
└────────┬────────┘
         │ Red alert detected
         ▼
┌─────────────┐
│  RED_ALERT  │ ← Active alert, "היכנסו למרחב המוגן"
└──────┬──────┘
       │ Alert ends (no longer in active list)
       ▼
┌───────────────┐
│ WAITING_CLEAR │ ← "המתינו במרחב המוגן"
└───────┬───────┘
        │ Clearance message received
        ▼
┌──────────────┐
│ JUST_CLEARED │ ← "האירוע הסתיים", temporary (10 min)
└──────┬───────┘
       │ 10 minutes elapsed
       ▼
┌─────────────┐
│  ALL_CLEAR  │
└─────────────┘
```

### State Enum
```dart
enum AlertState {
  allClear,       // No alerts, normal state
  alertImminent,  // Alerts expected soon
  redAlert,       // Active alert, seek shelter
  waitingClear,   // Alert ended, awaiting clearance
  justCleared,    // Clearance received, temporary state
}
```

### State Transitions

| From | To | Trigger |
|------|----|---------|
| ALL_CLEAR | ALERT_IMMINENT | Historical alert contains "בדקות הקרובות צפויות" for primary location |
| ALL_CLEAR | RED_ALERT | Active alert detected for primary location |
| ALERT_IMMINENT | RED_ALERT | Active alert detected for primary location |
| RED_ALERT | WAITING_CLEAR | Primary location no longer in active alerts list |
| WAITING_CLEAR | JUST_CLEARED | Historical alert contains "האירוע הסתיים" or "ניתן לצאת" for primary location |
| JUST_CLEARED | ALL_CLEAR | 10 minutes elapsed since clearance |
| Any state | ALL_CLEAR | User changes primary location (reset) |

### Timer Tracking
- `alertStartTime`: When RED_ALERT began (for elapsed timer display)
- `clearanceTime`: When JUST_CLEARED began (for 10-minute countdown)

### Location Matching

Matching user locations to alert locations requires fuzzy matching:
- Exact match: "תל אביב - מרכז" === "תל אביב - מרכז"
- Partial match: Alert for "תל אביב" matches user's "תל אביב - מרכז"
- Normalize whitespace, dashes, quotes

Reference: `src/utils/location-matcher.js`

## Location State

### Structure
```dart
class LocationState {
  final List<SavedLocation> locations;
  final String? primaryLocationId;
  
  SavedLocation? get primaryLocation => ...;
  List<SavedLocation> get secondaryLocations => ...;
}
```

### Persistence
- Store in SharedPreferences or Hive
- Load on app start
- Save on every change

### Operations
- Add location (with optional custom label)
- Edit location (change label)
- Delete location
- Set primary location
- Reorder locations (optional, for future)

## Data State

### Structure
```dart
class DataState {
  // Alerts
  final List<Alert> activeAlerts;
  final List<Alert> historicalAlerts;
  final List<String> availableLocations;
  
  // News
  final List<NewsItem> newsItems;
  
  // Status
  final bool isLoading;
  final bool isOffline;
  final String? errorMessage;
  final DateTime? lastUpdated;
}
```

### Computed Properties
- `alertsForLocation(String location)`: Filter alerts by location
- `nationwideAlertCount`: Total active alerts across all locations
- `userLocationAlertCount`: Active alerts in user's saved locations

## Provider Structure

```
providers/
├── alert_state_provider.dart    # AlertState enum + transitions
├── location_provider.dart       # SavedLocation CRUD + persistence
├── alerts_provider.dart         # Active + historical alerts data
├── news_provider.dart           # News items data
└── connectivity_provider.dart   # Online/offline status
```

## Acceptance Criteria

- [ ] Alert state machine transitions correctly through all states
- [ ] State persists timer values across transitions
- [ ] Location matching correctly identifies alerts for user locations
- [ ] Saved locations persist across app restarts
- [ ] Primary location change resets alert state to ALL_CLEAR
- [ ] Data state correctly tracks loading/error/offline states
- [ ] Providers notify listeners on state changes
- [ ] State updates trigger UI rebuilds efficiently

## References

Existing web app implementation:
- `src/utils/alert-state-machine.js` - State machine logic
- `src/utils/location-matcher.js` - Location matching
- `public/script.js` - State management integration (lines 878-1058)
