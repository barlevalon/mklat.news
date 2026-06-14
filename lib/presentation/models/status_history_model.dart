import '../../core/app_strings.dart';
import 'package:flutter/material.dart';

import '../../data/models/alert.dart';
import '../../domain/alert_state_machine.dart';

class StatusHistoryModel {
  final StatusHistoryState state;
  final List<Alert> alerts;
  final int displayCount;
  final bool hasMore;
  final String? message;
  final IconData? icon;

  const StatusHistoryModel._({
    required this.state,
    this.alerts = const [],
    this.displayCount = 0,
    this.hasMore = false,
    this.message,
    this.icon,
  });

  factory StatusHistoryModel.build({
    required List<Alert> alertHistory,
    required Set<String> savedLocationNames,
    required int displayedItemCount,
    required bool hasLocations,
    required bool isOffline,
    required bool isLoading,
    required String? currentAlertError,
    required String? historyError,
  }) {
    final filteredAlerts = _filterAlerts(alertHistory, savedLocationNames);
    final displayCount = filteredAlerts.length < displayedItemCount
        ? filteredAlerts.length
        : displayedItemCount;
    final hasMore = filteredAlerts.length > displayCount;

    if (isOffline) {
      return const StatusHistoryModel._(
        state: StatusHistoryState.offline,
        message: AppStrings.waitingForInternet,
        icon: Icons.signal_wifi_off,
      );
    }

    if (isLoading && filteredAlerts.isEmpty) {
      return const StatusHistoryModel._(
        state: StatusHistoryState.loading,
        message: AppStrings.loading,
      );
    }

    if (!hasLocations) {
      return const StatusHistoryModel._(
        state: StatusHistoryState.noLocations,
        message: AppStrings.addLocationToSeeAlerts,
        icon: Icons.location_off,
      );
    }

    if (currentAlertError != null && filteredAlerts.isEmpty) {
      return const StatusHistoryModel._(
        state: StatusHistoryState.currentAlertError,
        message: AppStrings.cannotShowAlertsNow,
        icon: Icons.cloud_off,
      );
    }

    if (historyError != null && filteredAlerts.isEmpty) {
      return StatusHistoryModel._(
        state: StatusHistoryState.historyError,
        message: historyError,
        icon: Icons.history_toggle_off,
      );
    }

    if (filteredAlerts.isEmpty) {
      return const StatusHistoryModel._(
        state: StatusHistoryState.empty,
        message: AppStrings.noRecentAlertsInYourAreas,
        icon: Icons.history_toggle_off,
      );
    }

    return StatusHistoryModel._(
      state: StatusHistoryState.data,
      alerts: filteredAlerts,
      displayCount: displayCount,
      hasMore: hasMore,
    );
  }

  static List<Alert> _filterAlerts(
    List<Alert> alertHistory,
    Set<String> savedLocationNames,
  ) {
    if (savedLocationNames.isEmpty) return [];

    return alertHistory.where((alert) {
      return savedLocationNames.any(
        (name) => AlertStateMachine.locationsMatch(alert.location, name),
      );
    }).toList();
  }
}

enum StatusHistoryState {
  offline,
  loading,
  noLocations,
  currentAlertError,
  historyError,
  empty,
  data,
}
