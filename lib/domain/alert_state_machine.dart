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
      _primaryLocation!,
      activeAlertLocations,
    );
    final hasClearance = _hasCategoryClearance(historyForPrimary, 13);
    final hasImminent = _hasCategoryClearance(historyForPrimary, 14);

    // Evaluation order (first match wins):

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

    // 2. Was RED_ALERT, location dropped, no cat 13 → WAITING_CLEAR
    if (_currentState == AlertState.redAlert && !isActive && !hasClearance) {
      _currentState = AlertState.waitingClear;
      return _buildResult();
    }

    // 3. Cat 13 in history → JUST_CLEARED (from ALERT_IMMINENT or WAITING_CLEAR)
    if (hasClearance &&
        (_currentState == AlertState.alertImminent ||
            _currentState == AlertState.waitingClear)) {
      _currentState = AlertState.justCleared;
      _clearanceTime = currentTime;
      return _buildResult();
    }

    // 4. Cat 14 in history → ALERT_IMMINENT (from ALL_CLEAR only)
    if (hasImminent && _currentState == AlertState.allClear) {
      _currentState = AlertState.alertImminent;
      return _buildResult();
    }

    // 5. JUST_CLEARED + 10 minutes elapsed → ALL_CLEAR
    if (_currentState == AlertState.justCleared && _clearanceTime != null) {
      final elapsed = currentTime.difference(_clearanceTime!);
      if (elapsed.inMinutes >= 10) {
        _currentState = AlertState.allClear;
        _alertStartTime = null;
        _clearanceTime = null;
        return _buildResult();
      }
    }

    // 6. Otherwise → remain in current state
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

  /// Check if history contains a given category for the primary location.
  bool _hasCategoryClearance(List<Alert> history, int category) {
    return history.any((alert) => alert.category == category);
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
