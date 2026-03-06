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
          ┌─────── │  ALL_CLEAR  │ ← Default state
          │        └──────┬──────┘
          │               │
          │     ┌─────────┴──────────┐
          │     │ cat 14             │ active alert
          │     ▼                    ▼
          │  ┌─────────────────┐  ┌─────────────┐
          │  │ ALERT_IMMINENT  │  │  RED_ALERT  │ ◄──────────┐
          │  └────────┬────────┘  └──────┬──────┘            │
          │           │                  │                   │
          │     ┌─────┴──────┐     alert drops,              │
          │     │ active     │ cat 13   no cat 13            │
          │     │ alert      │            │                  │
          │     ▼            │            ▼                  │
          │  RED_ALERT ──────│──► ┌───────────────┐          │
          │  (see above)     │    │ WAITING_CLEAR │ ─────────┘
          │                  │    └───────┬───────┘  active alert
          │                  │            │          (re-entry)
          │                  │      cat 13│
          │                  ▼            ▼
          │            ┌──────────────┐
          │            │ JUST_CLEARED │ ──────────────────────┐
          │            └──────┬───────┘  active alert         │
          │                   │          (re-entry to         │
          │           10 min  │           RED_ALERT) ─────────┘
          │                   │
          └───────────────────┘

Any state → ALL_CLEAR on primary location change.
No auto-timeouts on ALERT_IMMINENT or WAITING_CLEAR.
```

### State Enum
```dart
enum AlertState {
  allClear,       // No alerts, normal state
  alertImminent,  // Alerts expected soon (cat 14)
  redAlert,       // Active alert, seek shelter NOW
  waitingClear,   // Siren stopped, stay in shelter, awaiting "event ended"
  justCleared,    // Clearance received, temporary state (10 min)
}
```

### State Transitions

| From | To | Trigger |
|------|----|---------|
| ALL_CLEAR | ALERT_IMMINENT | Category 14 entry appears in alert history for primary location |
| ALL_CLEAR | RED_ALERT | Primary location appears in Alerts.json `data` array |
| ALERT_IMMINENT | RED_ALERT | Primary location appears in Alerts.json `data` array |
| ALERT_IMMINENT | JUST_CLEARED | Category 13 clearance appears for primary location (threat resolved without red alert) |
| RED_ALERT | WAITING_CLEAR | Primary location **no longer** in Alerts.json `data` array, and the latest relevant history signal is an actual attack (`cat 1/2`) or history has not caught up yet |
| WAITING_CLEAR | RED_ALERT | Primary location appears in Alerts.json `data` array again (new attack while in shelter) |
| WAITING_CLEAR | JUST_CLEARED | Category 13 entry appears in alert history for primary location |
| JUST_CLEARED | RED_ALERT | Primary location appears in Alerts.json `data` array (new attack during cooldown) |
| JUST_CLEARED | ALL_CLEAR | 10 minutes elapsed since clearance received |
| Any state | ALL_CLEAR | User changes primary location (reset) |

**Priority rule**: If the primary location is in the active alerts list, the state is always `RED_ALERT`, regardless of current state. Active alert detection takes absolute precedence.

**No auto-timeouts**: Neither `ALERT_IMMINENT` nor `WAITING_CLEAR` have automatic timeouts. Both persist until a definitive signal arrives (later history event, active alert, or user location change). The app never silently downgrades a heightened state.

**Self-loops**: If the state machine is already in `RED_ALERT` and the location is still in active alerts, it stays in `RED_ALERT` without resetting `alertStartTime`.

### Key Design: Replay ordered history

The `AlertsHistory.json` response for the primary location must be treated as an **ordered event stream**, not as a bag of categories. On each poll cycle:

1. If the primary location is currently active in `Alerts.json`, the result is always `RED_ALERT`
2. Otherwise, replay the relevant history events for that location in timestamp order
3. The latest meaningful history event determines the non-active state:
   - `cat 14` → `ALERT_IMMINENT`
   - `cat 1/2` → `WAITING_CLEAR`
   - `cat 13` → `JUST_CLEARED`

This means `WAITING_CLEAR` is still a safety-oriented state, but it is not limited to "the app previously observed `RED_ALERT` in this session". A history-only attack event (`cat 1/2`) can establish `WAITING_CLEAR` when the active feed has already gone quiet.

There is **no automatic timeout** for `WAITING_CLEAR`. The state persists until a later history event changes it, a new active alert overrides it, or the user changes their primary location. If an active alert just disappeared and history has not caught up yet, the machine should conservatively remain in `WAITING_CLEAR`.

### Timer Tracking
- `alertStartTime`: When RED_ALERT began (for elapsed timer display: "XX:XX במקלט")
- `clearanceTime`: When JUST_CLEARED began (for 10-minute countdown display)

### Inputs

Each poll cycle, the state machine receives two inputs:
1. **Active locations**: Set of location names from `Alerts.json` `data` array (empty if no alerts)
2. **History for primary location**: `Alert` entries from `AlertsHistory.json` where `data` matches the primary location

The `AlertsHistory.json` endpoint returns roughly the last hour of events. The state machine should use the **entire response** (not apply its own time window). The server controls the recency window.

### Evaluation order

The state machine evaluates in this priority order on each cycle:

1. **Is primary location in active alerts?** → `RED_ALERT` (from any state; do not reset `alertStartTime` if already in `RED_ALERT`)
2. **Otherwise, replay the full primary-location history in timestamp order** and derive the non-active state from the latest meaningful event (`14`, `1/2`, `13`)
3. **If replay yields `JUST_CLEARED` and 10 minutes have elapsed since the latest cat 13 event** → `ALL_CLEAR`
4. **If there is no relevant history but the previous state was `RED_ALERT` or `WAITING_CLEAR`** → remain in `WAITING_CLEAR` until history catches up or the user changes location
5. **Otherwise** → `ALL_CLEAR`

### Location Matching

Matching user locations to alert locations:
- **Primary match**: Exact string match between saved location `orefName` and alert `data`/`location`
- **Both values come from OREF**: The saved location name comes from the Districts endpoint, and alert location names come from Alerts.json/AlertsHistory.json. Since both originate from OREF, exact matching should work in most cases.
- **Edge case handling**: Normalize whitespace, handle Hebrew quote variants (`"`, `''`, `״`)
- **No fuzzy matching needed in MVP**: Both datasets use OREF's canonical names

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
- Store in SharedPreferences as JSON
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
  final List<String> activeAlertLocations;   // From Alerts.json data array
  final int? activeAlertCategory;            // From Alerts.json cat field
  final String? activeAlertTitle;            // From Alerts.json title field
  final List<Alert> alertHistory;            // From AlertsHistory.json
  final List<OrefLocation> availableLocations;
  
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
- `alertsForLocation(String location)`: Filter history alerts by location
- `nationwideAlertCount`: Count of distinct locations in active alerts
- `userLocationAlertCount`: Count of user's saved locations that are in active alerts
- `recentClearanceForLocation(String location)`: Find category 13 entry for a location
- `recentImminentForLocation(String location)`: Find category 14 entry for a location

## Provider Structure

```
providers/
├── alert_state_provider.dart    # AlertState enum + state machine + transitions
├── location_provider.dart       # SavedLocation CRUD + persistence
├── alerts_provider.dart         # Active alerts + history data
├── news_provider.dart           # News items data
└── connectivity_provider.dart   # Online/offline status
```

## Acceptance Criteria

- [ ] Alert state machine transitions correctly through all 5 states
- [ ] Active alert always produces RED_ALERT regardless of current state (priority rule)
- [ ] RED_ALERT self-loop does not reset alertStartTime
- [ ] WAITING_CLEAR is entered when the latest non-active signal is an attack event (`cat 1/2`) and no active alert is present
- [ ] WAITING_CLEAR has no auto-timeout — persists until clearance, new alert, or location change
- [ ] WAITING_CLEAR → RED_ALERT on re-entry (new attack while in shelter)
- [ ] JUST_CLEARED is entered when category 13 appears for the location (from ALERT_IMMINENT or WAITING_CLEAR)
- [ ] Latest relevant history event wins when categories from different phases coexist in the one-hour history window
- [ ] JUST_CLEARED → RED_ALERT on re-entry (new attack during cooldown)
- [ ] ALL_CLEAR → RED_ALERT works directly (no prior imminent required)
- [ ] State persists timer values across transitions
- [ ] Location matching correctly identifies alerts for user locations
- [ ] Saved locations persist across app restarts
- [ ] Primary location change resets alert state to ALL_CLEAR
- [ ] Data state correctly tracks loading/error/offline states
- [ ] Providers notify listeners on state changes
- [ ] State updates trigger UI rebuilds efficiently

## References

- API format documented in `01-data-layer.md` (validated 2026-03-04)
- Category mapping: 1=rockets, 2=UAV, 13=ended, 14=imminent
- Existing web app: `src/utils/alert-state-machine.js` (reference only — different trigger mechanism)
