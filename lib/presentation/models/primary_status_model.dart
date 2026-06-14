import '../../domain/alert_state.dart';

enum PrimaryStatusVisual { normal, offline, error }

class PrimaryStatusModel {
  final PrimaryStatusVisual visual;
  final AlertState alertState;
  final String icon;
  final String title;
  final String? instruction;
  final DateTime? elapsedStartTime;

  const PrimaryStatusModel._({
    required this.visual,
    required this.alertState,
    required this.icon,
    required this.title,
    required this.instruction,
    required this.elapsedStartTime,
  });

  factory PrimaryStatusModel.build({
    required bool isOffline,
    required String? alertErrorMessage,
    required AlertState alertState,
    required DateTime? alertStartTime,
  }) {
    if (isOffline) {
      return const PrimaryStatusModel._(
        visual: PrimaryStatusVisual.offline,
        alertState: AlertState.allClear,
        icon: '📡',
        title: 'אין חיבור',
        instruction: null,
        elapsedStartTime: null,
      );
    }

    if (alertErrorMessage != null) {
      return const PrimaryStatusModel._(
        visual: PrimaryStatusVisual.error,
        alertState: AlertState.allClear,
        icon: '⚠️',
        title: 'מצב לא ידוע',
        instruction: 'לא ניתן לאמת התרעות כרגע',
        elapsedStartTime: null,
      );
    }

    return PrimaryStatusModel._(
      visual: PrimaryStatusVisual.normal,
      alertState: alertState,
      icon: alertState.icon,
      title: alertState.hebrewTitle,
      instruction: alertState.instruction,
      elapsedStartTime: alertState.showElapsedTimer ? alertStartTime : null,
    );
  }

  bool get showInstruction => instruction != null;
  bool get showElapsedTimer => elapsedStartTime != null;
}
