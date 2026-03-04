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
| RED_ALERT | WAITING_CLEAR | Primary location **no longer** in Alerts.json `data` array, AND no category 13 clearance for this location in recent history |
| WAITING_CLEAR | RED_ALERT | Primary location appears in Alerts.json `data` array again (new attack while in shelter) |
| WAITING_CLEAR | JUST_CLEARED | Category 13 entry appears in alert history for primary location |
| JUST_CLEARED | RED_ALERT | Primary location appears in Alerts.json `data` array (new attack during cooldown) |
| JUST_CLEARED | ALL_CLEAR | 10 minutes elapsed since clearance received |
| Any state | ALL_CLEAR | User changes primary location (reset) |

**Priority rule**: If the primary location is in the active alerts list, the state is always `RED_ALERT`, regardless of current state. Active alert detection takes absolute precedence.

**No auto-timeouts**: Neither `ALERT_IMMINENT` nor `WAITING_CLEAR` have automatic timeouts. Both persist until a definitive signal arrives (cat 13 clearance, active alert, or user location change). The app never silently downgrades a heightened state.

**Self-loops**: If the state machine is already in `RED_ALERT` and the location is still in active alerts, it stays in `RED_ALERT` without resetting `alertStartTime`.

### Key Design: WAITING_CLEAR is absence-based

The `WAITING_CLEAR` state represents the real-world experience of sitting in the shelter after the siren stops, waiting for the official all-clear. It is detected by **absence**, not presence:

1. The state machine tracks that we **were** in `RED_ALERT`
2. The active alert disappears from `Alerts.json` (siren stopped)
3. But no category 13 ("האירוע הסתיים") has appeared for this location in the history yet
4. Therefore: stay in shelter

This is fundamentally different from the other transitions which are triggered by data appearing. The state machine must maintain internal memory of having been in `RED_ALERT` to correctly enter `WAITING_CLEAR`.

There is **no automatic timeout** for `WAITING_CLEAR`. The state persists until a category 13 clearance signal arrives or the user changes their primary location (which resets to `ALL_CLEAR`). This is a safety-critical state — silently auto-clearing could endanger users. If the clearance signal is never received due to an API issue, the user retains control by changing their location.

### Timer Tracking
- `alertStartTime`: When RED_ALERT began (for elapsed timer display: "XX:XX במקלט")
- `clearanceTime`: When JUST_CLEARED began (for 10-minute countdown display)

### Inputs

Each poll cycle, the state machine receives two inputs:
1. **Active locations**: Set of location names from `Alerts.json` `data` array (empty if no alerts)
2. **History for primary location**: `Alert` entries from `AlertsHistory.json` where `data` matches the primary location

The `AlertsHistory.json` endpoint returns roughly the last hour of events. The state machine should use the **entire response** (not apply its own time window). The server controls the recency window.

### Evaluation order

The state machine evaluates in this priority order on each cycle (first match wins):

1. **Is primary location in active alerts?** → `RED_ALERT` (from any state; do not reset `alertStartTime` if already in `RED_ALERT`)
2. **Is current state `RED_ALERT` and location no longer active, with no cat 13 in history?** → `WAITING_CLEAR`
3. **Is there a category 13 for primary location in history?** → `JUST_CLEARED` (from `ALERT_IMMINENT` or `WAITING_CLEAR`)
4. **Is there a category 14 for primary location in history?** → `ALERT_IMMINENT` (from `ALL_CLEAR` only)
5. **Is current state `JUST_CLEARED` and 10 minutes elapsed?** → `ALL_CLEAR`
6. **Otherwise** → remain in current state

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
- [ ] WAITING_CLEAR is entered when active alert drops but no clearance received
- [ ] WAITING_CLEAR has no auto-timeout — persists until clearance, new alert, or location change
- [ ] WAITING_CLEAR → RED_ALERT on re-entry (new attack while in shelter)
- [ ] JUST_CLEARED is entered when category 13 appears for the location (from ALERT_IMMINENT or WAITING_CLEAR)
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
