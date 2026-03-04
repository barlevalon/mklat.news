import 'package:flutter/foundation.dart';
import '../../data/models/alert.dart';
import '../../domain/alert_state.dart';
import '../../domain/alert_state_machine.dart';

class AlertsProvider extends ChangeNotifier {
  final AlertStateMachine _stateMachine = AlertStateMachine();

  List<Alert> _currentAlerts = [];
  List<Alert> _alertHistory = [];
  bool _isLoading = true;
  bool _isResuming = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Public getters
  AlertState get alertState => _stateMachine.currentState;
  DateTime? get alertStartTime => _stateMachine.alertStartTime;
  DateTime? get clearanceTime => _stateMachine.clearanceTime;
  List<Alert> get currentAlerts => List.unmodifiable(_currentAlerts);
  List<Alert> get alertHistory => List.unmodifiable(_alertHistory);
  bool get isLoading => _isLoading;
  bool get isResuming => _isResuming;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;

  /// Active alert locations (from current Alerts.json)
  Set<String> get activeAlertLocations =>
      _currentAlerts.map((a) => a.location).toSet();

  /// Nationwide alert count (distinct locations in active alerts)
  int get nationwideAlertCount => activeAlertLocations.length;

  /// Count of user's saved locations that are in active alerts
  int userLocationAlertCount(List<String> savedLocationNames) {
    return savedLocationNames
        .where(
          (name) => activeAlertLocations.any(
            (alertLoc) => AlertStateMachine.locationsMatch(alertLoc, name),
          ),
        )
        .length;
  }

  /// Get history alerts filtered for a specific location
  List<Alert> alertsForLocation(String locationName) {
    return _alertHistory
        .where(
          (a) => AlertStateMachine.locationsMatch(a.location, locationName),
        )
        .toList();
  }

  /// Set the primary location on the state machine.
  /// Called by the UI when the user changes primary location.
  void setPrimaryLocation(String? locationName) {
    _stateMachine.setPrimaryLocation(locationName);
    notifyListeners();
  }

  /// Set the resuming state. Called when app resumes from background.
  void setResuming(bool value) {
    _isResuming = value;
    notifyListeners();
  }

  /// Called by polling manager with fresh alert data.
  void onAlertData(List<Alert> current, List<Alert> history) {
    _currentAlerts = current;
    _alertHistory = history;
    _isLoading = false;
    _isResuming = false; // Clear resume state on fresh data
    _errorMessage = null;
    _lastUpdated = DateTime.now();

    // Run state machine evaluation
    _evaluateState();
    notifyListeners();
  }

  /// Called by polling manager on error.
  void onError(String source, Object error) {
    _errorMessage = 'שגיאה בטעינת התרעות';
    notifyListeners();
  }

  void _evaluateState() {
    final primaryName = _stateMachine.primaryLocation;
    if (primaryName == null) return;

    // Filter history for primary location
    final historyForPrimary = _alertHistory
        .where((a) => AlertStateMachine.locationsMatch(a.location, primaryName))
        .toList();

    _stateMachine.evaluate(
      activeAlertLocations: activeAlertLocations,
      historyForPrimary: historyForPrimary,
    );
  }

  /// Check if a specific location is in active alerts
  bool isLocationInActiveAlerts(String locationName) {
    return activeAlertLocations.any(
      (alertLoc) => AlertStateMachine.locationsMatch(alertLoc, locationName),
    );
  }
}
