import '../../data/models/alert.dart';
import '../../data/models/saved_location.dart';
import '../../domain/alert_state_machine.dart';
import '../../domain/saved_locations.dart';
import 'status_history_model.dart';

enum SecondaryLocationDotState { inactive, active, unavailable }

class SecondaryLocationChipModel {
  final String label;
  final String orefName;
  final SecondaryLocationDotState dotState;

  const SecondaryLocationChipModel({
    required this.label,
    required this.orefName,
    required this.dotState,
  });
}

class NationwideSummaryModel {
  final int userLocationCount;
  final int nationwideCount;

  const NationwideSummaryModel({
    required this.userLocationCount,
    required this.nationwideCount,
  });
}

class StatusErrorBannerModel {
  final String message;

  const StatusErrorBannerModel(this.message);
}

class StatusPresentationModel {
  final StatusHistoryModel history;
  final StatusErrorBannerModel? errorBanner;
  final List<SecondaryLocationChipModel> secondaryLocationChips;
  final NationwideSummaryModel? nationwideSummary;
  final bool showLastHourLabel;

  const StatusPresentationModel({
    required this.history,
    required this.errorBanner,
    required this.secondaryLocationChips,
    required this.nationwideSummary,
    required this.showLastHourLabel,
  });

  factory StatusPresentationModel.build({
    required List<Alert> currentAlerts,
    required List<Alert> alertHistory,
    required List<SavedLocation> savedLocations,
    required int displayedItemCount,
    required bool isOffline,
    required bool isLoading,
    required String? currentAlertError,
    required String? historyError,
  }) {
    final normalizedLocations = normalizeSavedLocations(savedLocations);
    final savedLocationNames = normalizedLocations
        .map((location) => location.orefName)
        .toSet();
    final activeAlertLocations = currentAlerts
        .map((alert) => alert.location)
        .toSet();
    final history = StatusHistoryModel.build(
      alertHistory: alertHistory,
      savedLocationNames: savedLocationNames,
      displayedItemCount: displayedItemCount,
      hasLocations: normalizedLocations.isNotEmpty,
      isOffline: isOffline,
      isLoading: isLoading,
      currentAlertError: currentAlertError,
      historyError: historyError,
    );

    return StatusPresentationModel(
      history: history,
      errorBanner: currentAlertError == null
          ? null
          : StatusErrorBannerModel(currentAlertError),
      secondaryLocationChips: currentAlertError == null
          ? _buildSecondaryLocationChips(
              savedLocations: normalizedLocations,
              activeAlertLocations: activeAlertLocations,
              isUnavailable: isOffline,
            )
          : const [],
      nationwideSummary: _buildNationwideSummary(
        activeAlertLocations: activeAlertLocations,
        savedLocationNames: savedLocationNames,
      ),
      showLastHourLabel: !isOffline && history.alerts.isNotEmpty,
    );
  }

  static List<SecondaryLocationChipModel> _buildSecondaryLocationChips({
    required List<SavedLocation> savedLocations,
    required Set<String> activeAlertLocations,
    required bool isUnavailable,
  }) {
    final primary = savedLocations.where((location) => location.isPrimary);
    final primaryId = primary.isEmpty ? null : primary.first.id;
    return savedLocations
        .where((location) => location.id != primaryId)
        .map(
          (location) => SecondaryLocationChipModel(
            label: location.displayLabel,
            orefName: location.orefName,
            dotState: isUnavailable
                ? SecondaryLocationDotState.unavailable
                : _isLocationActive(location.orefName, activeAlertLocations)
                ? SecondaryLocationDotState.active
                : SecondaryLocationDotState.inactive,
          ),
        )
        .toList();
  }

  static NationwideSummaryModel? _buildNationwideSummary({
    required Set<String> activeAlertLocations,
    required Set<String> savedLocationNames,
  }) {
    if (activeAlertLocations.isEmpty) return null;

    final userLocationCount = savedLocationNames
        .where((name) => _isLocationActive(name, activeAlertLocations))
        .length;
    return NationwideSummaryModel(
      userLocationCount: userLocationCount,
      nationwideCount: activeAlertLocations.length,
    );
  }

  static bool _isLocationActive(
    String locationName,
    Set<String> activeAlertLocations,
  ) {
    return activeAlertLocations.any(
      (activeLocation) =>
          AlertStateMachine.locationsMatch(activeLocation, locationName),
    );
  }
}
