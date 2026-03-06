import 'alert_state.dart';
import '../data/models/alert.dart';

/// Result of a state machine evaluation
class AlertStateResult {
  final AlertState state;
  final DateTime? alertStartTime; // When RED_ALERT began
  final DateTime? clearanceTime; // When JUST_CLEARED began

  const AlertStateResult({
    required this.state,
    this.alertStartTime,
    this.clearanceTime,
  });
}

class _DerivedHistoryState {
  final AlertState state;
  final DateTime? alertStartTime;
  final DateTime? clearanceTime;

  const _DerivedHistoryState({
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
      _alertStartTime = null;
      _clearanceTime = null;
      return _buildResult();
    }

    final isActive = _isLocationInActiveAlerts(
      _primaryLocation!,
      activeAlertLocations,
    );
    final derived = _deriveStateFromHistory(historyForPrimary, currentTime);

    // Active alert always wins.
    if (isActive) {
      if (_currentState != AlertState.redAlert) {
        _alertStartTime = derived.alertStartTime ?? currentTime;
      }
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
    final indexedHistory =
        history.asMap().entries.where((entry) {
          final category = entry.value.category;
          return category == 1 ||
              category == 2 ||
              category == 13 ||
              category == 14;
        }).toList()..sort((a, b) {
          final timeComparison = a.value.time.compareTo(b.value.time);
          if (timeComparison != 0) return timeComparison;
          return a.key.compareTo(b.key);
        });

    var state = AlertState.allClear;
    DateTime? alertStartTime;
    DateTime? clearanceTime;

    for (final entry in indexedHistory) {
      final alert = entry.value;
      switch (alert.category) {
        case 14:
          state = AlertState.alertImminent;
          alertStartTime = null;
          clearanceTime = null;
          break;
        case 1:
        case 2:
          state = AlertState.waitingClear;
          alertStartTime = alert.time;
          clearanceTime = null;
          break;
        case 13:
          state = AlertState.justCleared;
          clearanceTime = alert.time;
          break;
      }
    }

    if (state == AlertState.justCleared && clearanceTime != null) {
      final elapsed = now.difference(clearanceTime);
      if (elapsed.inMinutes >= 10) {
        return const _DerivedHistoryState(state: AlertState.allClear);
      }
    }

    return _DerivedHistoryState(
      state: state,
      alertStartTime: alertStartTime,
      clearanceTime: clearanceTime,
    );
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

  /// Public utility for location name matching (used by providers too)
  static bool locationsMatch(String a, String b) {
    return _normalizeLocationName(a) == _normalizeLocationName(b);
  }
}
