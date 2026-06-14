import '../../core/app_strings.dart';
import '../../domain/alert_state.dart';

class AlertStatePresentation {
  final String title;
  final String? instruction;
  final String icon;

  const AlertStatePresentation({
    required this.title,
    required this.instruction,
    required this.icon,
  });

  factory AlertStatePresentation.fromState(AlertState state) {
    switch (state) {
      case AlertState.allClear:
        return const AlertStatePresentation(
          title: AppStrings.alertStateAllClear,
          instruction: null,
          icon: '🟢',
        );
      case AlertState.alertImminent:
        return const AlertStatePresentation(
          title: AppStrings.alertStateImminent,
          instruction: AppStrings.alertInstructionImminent,
          icon: '⚠️',
        );
      case AlertState.redAlert:
        return const AlertStatePresentation(
          title: AppStrings.alertStateRedAlert,
          instruction: AppStrings.alertInstructionTakeShelter,
          icon: '🚨',
        );
      case AlertState.waitingClear:
        return const AlertStatePresentation(
          title: AppStrings.alertStateWaitingClear,
          instruction: AppStrings.alertInstructionWaitClear,
          icon: '◷',
        );
      case AlertState.justCleared:
        return const AlertStatePresentation(
          title: AppStrings.alertStateJustCleared,
          instruction: AppStrings.alertInstructionCleared,
          icon: '✅',
        );
    }
  }
}
