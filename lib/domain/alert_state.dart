/// Alert states for the primary location state machine
enum AlertState {
  /// No alerts, normal state
  /// Display: 🟢 אין התרעות
  allClear,

  /// Alerts expected soon (category 14 imminent warning)
  /// Display: ⚠️ התרעה צפויה
  alertImminent,

  /// Active alert, seek shelter NOW
  /// Display: 🚨 צבע אדום + timer
  redAlert,

  /// Siren stopped, stay in shelter, awaiting "event ended"
  /// Display: ◷ המתינו במרחב המוגן + timer
  waitingClear,

  /// Clearance received, temporary 10-minute state
  /// Display: ✅ האירוע הסתיים
  justCleared,
}

extension AlertStateExtension on AlertState {
  /// Get Hebrew display text for this state
  String get hebrewTitle {
    switch (this) {
      case AlertState.allClear:
        return 'אין התרעות';
      case AlertState.alertImminent:
        return 'התרעה צפויה';
      case AlertState.redAlert:
        return 'צבע אדום';
      case AlertState.waitingClear:
        return 'המתינו במרחב המוגן';
      case AlertState.justCleared:
        return 'האירוע הסתיים';
    }
  }

  /// Get instruction text for this state
  String? get instruction {
    switch (this) {
      case AlertState.allClear:
        return null;
      case AlertState.alertImminent:
        return 'התרעות צפויות בדקות הקרובות';
      case AlertState.redAlert:
        return 'היכנסו למרחב המוגן';
      case AlertState.waitingClear:
        return 'ממתינים לאישור יציאה';
      case AlertState.justCleared:
        return 'ניתן לצאת מהמרחב המוגן';
    }
  }

  /// Get emoji/icon indicator for this state
  String get icon {
    switch (this) {
      case AlertState.allClear:
        return '🟢';
      case AlertState.alertImminent:
        return '⚠️';
      case AlertState.redAlert:
        return '🚨';
      case AlertState.waitingClear:
        return '◷';
      case AlertState.justCleared:
        return '✅';
    }
  }

  /// Whether this state should display an elapsed timer
  bool get showElapsedTimer =>
      this == AlertState.redAlert || this == AlertState.waitingClear;

  /// Whether this is an elevated alert state (not all clear)
  bool get isElevated => this != AlertState.allClear;

  /// Whether this is an active danger state
  bool get isDanger =>
      this == AlertState.redAlert || this == AlertState.waitingClear;
}
