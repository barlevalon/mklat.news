import '../../core/app_strings.dart';
import '../../domain/alert_state.dart';
import 'alert_state_presentation.dart';

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
        title: AppStrings.noConnection,
        instruction: null,
        elapsedStartTime: null,
      );
    }

    if (alertErrorMessage != null) {
      return const PrimaryStatusModel._(
        visual: PrimaryStatusVisual.error,
        alertState: AlertState.allClear,
        icon: '⚠️',
        title: AppStrings.unknownStatus,
        instruction: AppStrings.cannotVerifyAlerts,
        elapsedStartTime: null,
      );
    }

    final presentation = AlertStatePresentation.fromState(alertState);
    return PrimaryStatusModel._(
      visual: PrimaryStatusVisual.normal,
      alertState: alertState,
      icon: presentation.icon,
      title: presentation.title,
      instruction: presentation.instruction,
      elapsedStartTime: alertState.showElapsedTimer ? alertStartTime : null,
    );
  }

  bool get showInstruction => instruction != null;
  bool get showElapsedTimer => elapsedStartTime != null;
}
