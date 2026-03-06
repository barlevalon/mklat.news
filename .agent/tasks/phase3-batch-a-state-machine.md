# Phase 3 Batch A: Alert State Machine

## Context

Implement the core alert state machine that drives the primary location's status display. This is the most critical business logic in the app -- it determines whether a user should be in a shelter or not.

Read these before starting:
- `.agent/specs/02-state-management.md` — full state machine spec (states, transitions, evaluation order, timer tracking)
- `lib/domain/alert_state.dart` — existing AlertState enum
- `lib/data/models/alert.dart` — Alert model (used as input)

## Architecture

```
lib/domain/
├── alert_state.dart          # Already exists (enum + extensions)
└── alert_state_machine.dart  # NEW: state machine class
```

## Task 1: Alert State Machine

**File:** `lib/domain/alert_state_machine.dart`

### Class Design

```dart
import 'alert_state.dart';
import '../data/models/alert.dart';

/// Result of a state machine evaluation
class AlertStateResult {
  final AlertState state;
  final DateTime? alertStartTime;   // When RED_ALERT began
  final DateTime? clearanceTime;    // When JUST_CLEARED began
  
  const AlertStateResult({
    required this.state,
    this.alertStartTime,
    this.clearanceTime,
  });
}

class AlertStateMachine {
  AlertState _currentState = AlertState.allClear;
  DateTime? _alertStartTime;
  DateTime? _clearanceTime;
  String? _primaryLocation;
  
  AlertState get currentState => _currentState;
  DateTime? get alertStartTime => _alertStartTime;
  DateTime? get clearanceTime => _clearanceTime;
  String? get primaryLocation => _primaryLocation;

  /// Set the primary location. Resets state to ALL_CLEAR.
  void setPrimaryLocation(String? location) {
    if (location != _primaryLocation) {
      _primaryLocation = location;
      _currentState = AlertState.allClear;
      _alertStartTime = null;
      _clearanceTime = null;
    }
  }

  /// Evaluate state based on current data.
  /// Called every poll cycle (every 2 seconds).
  /// 
  /// [activeAlertLocations] - Set of location names currently in Alerts.json data array
  /// [historyForPrimary] - Alert history entries matching the primary location
  /// [now] - Current time (injectable for testing)
  AlertStateResult evaluate({
    required Set<String> activeAlertLocations,
    required List<Alert> historyForPrimary,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    
    if (_primaryLocation == null) {
      _currentState = AlertState.allClear;
      return _buildResult();
    }

    final isActive = _isLocationInActiveAlerts(
      _primaryLocation!, activeAlertLocations,
    );
    final derived = _deriveStateFromHistory(historyForPrimary, currentTime);

    // Active alert always wins.
    
    // 1. Active alert → RED_ALERT (from any state)
    if (isActive) {
      if (_currentState != AlertState.redAlert) {
        _alertStartTime = currentTime;
      }
      // Self-loop: don't reset alertStartTime
      _currentState = AlertState.redAlert;
      _clearanceTime = null;
      return _buildResult();
    }

    // Replay the ordered history stream to establish the current non-active state.
    if (derived.state != AlertState.allClear) {
      _currentState = derived.state;
      _alertStartTime = derived.alertStartTime;
      _clearanceTime = derived.clearanceTime;
      return _buildResult();
    }

    // If active alert just disappeared and history has not caught up yet,
    // stay conservative and keep the user in WAITING_CLEAR.
    if (_currentState == AlertState.redAlert ||
        _currentState == AlertState.waitingClear) {
      _currentState = AlertState.waitingClear;
      _alertStartTime ??= currentTime;
      _clearanceTime = null;
      return _buildResult();
    }

    // Otherwise reset to ALL_CLEAR.
    _currentState = AlertState.allClear;
    _alertStartTime = null;
    _clearanceTime = null;
    return _buildResult();
  }

  /// Reset state machine to initial state
  void reset() {
    _currentState = AlertState.allClear;
    _alertStartTime = null;
    _clearanceTime = null;
    _primaryLocation = null;
  }

  AlertStateResult _buildResult() {
    return AlertStateResult(
      state: _currentState,
      alertStartTime: _alertStartTime,
      clearanceTime: _clearanceTime,
    );
  }

  /// Check if the primary location matches any active alert location.
  /// Uses normalized matching (whitespace normalization, Hebrew quote variants).
  bool _isLocationInActiveAlerts(
    String primaryLocation,
    Set<String> activeLocations,
  ) {
    final normalizedPrimary = _normalizeLocationName(primaryLocation);
    return activeLocations.any(
      (loc) => _normalizeLocationName(loc) == normalizedPrimary,
    );
  }

  _DerivedHistoryState _deriveStateFromHistory(
    List<Alert> history,
    DateTime now,
  ) {
    // Filter to relevant categories and replay them in timestamp order.
    // Latest meaningful event wins for the non-active state:
    // 14 -> ALERT_IMMINENT, 1/2 -> WAITING_CLEAR, 13 -> JUST_CLEARED.
    // If JUST_CLEARED is older than 10 minutes, collapse to ALL_CLEAR.
  }

  /// Normalize location name for matching.
  /// - Collapse whitespace
  /// - Normalize Hebrew quote variants (", '', ״)
  static String _normalizeLocationName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('״', '"')
        .replaceAll("''", '"');
  }
}
```

### Important Design Notes

1. **`evaluate()` takes `now` parameter** — for deterministic testing of time-based transitions (JUST_CLEARED → ALL_CLEAR after 10 minutes).

2. **History is pre-filtered by caller** — `historyForPrimary` should only contain entries for the primary location. The state machine doesn't filter; it trusts the caller. This keeps the machine focused on transitions.

3. **`_isLocationInActiveAlerts` does set membership** — the spec says active alert takes priority. The caller extracts `data[]` from Alerts.json into a Set<String>.

4. **History is an ordered stream** — do not treat `historyForPrimary` as unordered category flags. Replay it in timestamp order and let the latest meaningful event determine the non-active state.

5. **`setPrimaryLocation` resets state** — changing primary location always resets to ALL_CLEAR.

6. **Static `_normalizeLocationName`** — make it static so it can also be used by providers for filtering history. Actually, better to make it a public utility:

Add a public static method:
```dart
/// Public utility for location name matching (used by providers too)
static bool locationsMatch(String a, String b) {
  return _normalizeLocationName(a) == _normalizeLocationName(b);
}
```

---

## Task 2: Comprehensive Unit Tests

**File:** `test/unit/alert_state_machine_test.dart`

This is the most critical test file in the app. Every state transition path must be tested.

### Required test cases (from spec acceptance criteria):

**Basic transitions:**
1. Initial state is ALL_CLEAR
2. ALL_CLEAR → RED_ALERT when primary location in active alerts
3. ALL_CLEAR → ALERT_IMMINENT when cat 14 in history
4. ALERT_IMMINENT → RED_ALERT when primary location in active alerts
5. ALERT_IMMINENT → JUST_CLEARED when cat 13 in history (threat resolved without red alert)
6. RED_ALERT → WAITING_CLEAR when location drops from active, no cat 13
7. WAITING_CLEAR → JUST_CLEARED when cat 13 in history
8. WAITING_CLEAR → RED_ALERT when location reappears in active (re-entry)
9. JUST_CLEARED → ALL_CLEAR after 10 minutes
10. JUST_CLEARED → RED_ALERT on new attack during cooldown

**Full paths:**
11. Full path: ALL_CLEAR → ALERT_IMMINENT → RED_ALERT → WAITING_CLEAR → JUST_CLEARED → ALL_CLEAR
12. Direct path: ALL_CLEAR → RED_ALERT (no prior imminent)
13. Short path: ALERT_IMMINENT → JUST_CLEARED (threat resolved)
14. Re-entry: WAITING_CLEAR → RED_ALERT → WAITING_CLEAR → JUST_CLEARED

**Priority rules:**
15. Active alert ALWAYS wins → RED_ALERT regardless of current state
16. RED_ALERT self-loop: alertStartTime NOT reset when staying in RED_ALERT
17. RED_ALERT → RED_ALERT preserves alertStartTime

**WAITING_CLEAR specifics:**
18. WAITING_CLEAR has NO auto-timeout (stays indefinitely)
19. WAITING_CLEAR can be established by a history-only attack event (`cat 1/2`) even if the app did not observe `RED_ALERT` in-session
20. If an active alert just disappeared and no newer history event exists yet, keep the user in WAITING_CLEAR conservatively

**Location management:**
21. setPrimaryLocation resets to ALL_CLEAR from any state
22. setPrimaryLocation(same value) does NOT reset state
23. setPrimaryLocation(null) → ALL_CLEAR
24. null primary location → always ALL_CLEAR regardless of inputs

**Location matching:**
25. Exact match works
26. Whitespace normalization works
27. Hebrew quote normalization works (״ → ")
28. Double-single-quote normalization works ('' → ")
29. No match returns false

**Timer tracking:**
30. alertStartTime set when entering RED_ALERT
31. alertStartTime preserved during RED_ALERT self-loop
32. alertStartTime cleared when returning to ALL_CLEAR
33. clearanceTime set when entering JUST_CLEARED
34. clearanceTime cleared when returning to ALL_CLEAR
35. JUST_CLEARED → ALL_CLEAR at exactly 10 minutes

**Edge cases:**
36. Empty active alerts + empty history → ALL_CLEAR, unless conservatively carrying forward WAITING_CLEAR after a just-dropped active alert
37. Mixed cat 13/cat 14/cat 1 history → newest relevant event wins
38. Active alert AND cat 13 in history → RED_ALERT wins (evaluation order rule 1)
39. reset() returns to initial state

### Test pattern:

```dart
test('ALL_CLEAR → RED_ALERT when primary in active alerts', () {
  final machine = AlertStateMachine();
  machine.setPrimaryLocation('תל אביב - מרכז');

  final result = machine.evaluate(
    activeAlertLocations: {'תל אביב - מרכז', 'חיפה'},
    historyForPrimary: [],
  );

  expect(result.state, AlertState.redAlert);
  expect(result.alertStartTime, isNotNull);
});
```

For time-based tests, use the `now` parameter:

```dart
test('JUST_CLEARED → ALL_CLEAR after 10 minutes', () {
  final machine = AlertStateMachine();
  machine.setPrimaryLocation('תל אביב - מרכז');
  final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

  // Enter RED_ALERT
  machine.evaluate(
    activeAlertLocations: {'תל אביב - מרכז'},
    historyForPrimary: [],
    now: baseTime,
  );

  // Enter WAITING_CLEAR (alert drops, no cat 13)
  machine.evaluate(
    activeAlertLocations: {},
    historyForPrimary: [],
    now: baseTime.add(Duration(minutes: 1)),
  );

  // Enter JUST_CLEARED (cat 13 arrives)
  machine.evaluate(
    activeAlertLocations: {},
    historyForPrimary: [Alert(id: '1', location: 'תל אביב - מרכז', title: 'test', time: baseTime, category: 13)],
    now: baseTime.add(Duration(minutes: 2)),
  );
  expect(machine.currentState, AlertState.justCleared);

  // Still JUST_CLEARED at 9 minutes
  machine.evaluate(
    activeAlertLocations: {},
    historyForPrimary: [Alert(id: '1', location: 'תל אביב - מרכז', title: 'test', time: baseTime, category: 13)],
    now: baseTime.add(Duration(minutes: 11)),
  );
  expect(machine.currentState, AlertState.justCleared);

  // ALL_CLEAR at 12 minutes (10 minutes after clearanceTime at minute 2)
  machine.evaluate(
    activeAlertLocations: {},
    historyForPrimary: [Alert(id: '1', location: 'תל אביב - מרכז', title: 'test', time: baseTime, category: 13)],
    now: baseTime.add(Duration(minutes: 12)),
  );
  expect(machine.currentState, AlertState.allClear);
});
```

---

## Verification

```bash
flutter analyze
flutter test
```

Both must pass with zero errors.

## Files to create

1. `lib/domain/alert_state_machine.dart`
2. `test/unit/alert_state_machine_test.dart`
