import '../../core/app_strings.dart';
import '../../data/models/alert.dart';

class AlertCategoryPresentation {
  final String title;
  final String? instruction;
  final String icon;

  const AlertCategoryPresentation({
    required this.title,
    required this.instruction,
    required this.icon,
  });

  factory AlertCategoryPresentation.fromCategory(AlertCategory category) {
    switch (category) {
      case AlertCategory.rockets:
        return const AlertCategoryPresentation(
          title: AppStrings.alertCategoryRockets,
          instruction: AppStrings.alertInstructionTakeShelter,
          icon: '🚨',
        );
      case AlertCategory.uav:
        return const AlertCategoryPresentation(
          title: AppStrings.alertCategoryUav,
          instruction: AppStrings.alertInstructionTakeShelter,
          icon: '🚨',
        );
      case AlertCategory.clearance:
        return const AlertCategoryPresentation(
          title: AppStrings.alertCategoryClearance,
          instruction: AppStrings.alertInstructionCleared,
          icon: '✅',
        );
      case AlertCategory.imminent:
        return const AlertCategoryPresentation(
          title: AppStrings.alertCategoryImminent,
          instruction: AppStrings.alertInstructionImminent,
          icon: '⚠️',
        );
      case AlertCategory.other:
        return const AlertCategoryPresentation(
          title: AppStrings.alertCategoryOther,
          instruction: null,
          icon: '📍',
        );
    }
  }
}
