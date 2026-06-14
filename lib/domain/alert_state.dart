/// Alert states for the primary location state machine
enum AlertState {
  /// No alerts, normal state
  /// Presentation: all clear.
  allClear,

  /// Alerts expected soon (category 14 imminent warning)
  /// Presentation: imminent warning.
  alertImminent,

  /// Active alert, seek shelter NOW
  /// Presentation: active red alert with timer.
  redAlert,

  /// Siren stopped, stay in shelter, awaiting "event ended"
  /// Presentation: waiting for clearance with timer.
  waitingClear,

  /// Clearance received, temporary 10-minute state
  /// Presentation: just cleared.
  justCleared,
}

extension AlertStateExtension on AlertState {
  /// Whether this state should display an elapsed timer
  bool get showElapsedTimer =>
      this == AlertState.redAlert || this == AlertState.waitingClear;

  /// Whether this is an elevated alert state (not all clear)
  bool get isElevated => this != AlertState.allClear;

  /// Whether this is an active danger state
  bool get isDanger =>
      this == AlertState.redAlert || this == AlertState.waitingClear;
}
