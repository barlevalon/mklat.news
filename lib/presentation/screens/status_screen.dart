import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../models/status_history_model.dart';
import '../models/status_presentation_model.dart';
import '../providers/alerts_provider.dart';
import '../providers/location_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/primary_status_card.dart';
import '../widgets/secondary_locations_row.dart';
import '../widgets/nationwide_summary.dart';
import '../widgets/alert_list_item.dart';
import '../widgets/content_state_placeholder.dart';

class StatusScreen extends StatefulWidget {
  const StatusScreen({super.key});

  @override
  State<StatusScreen> createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int _displayedItemCount = 20;

  void _loadMore() {
    setState(() {
      _displayedItemCount += 20;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<AlertsProvider, LocationProvider, ConnectivityProvider>(
      builder:
          (
            context,
            alertsProvider,
            locationProvider,
            connectivityProvider,
            child,
          ) {
            final model = StatusPresentationModel.build(
              currentAlerts: alertsProvider.currentAlerts,
              alertHistory: alertsProvider.alertHistory,
              savedLocations: locationProvider.locations,
              displayedItemCount: _displayedItemCount,
              isOffline: connectivityProvider.isOffline,
              isLoading: alertsProvider.isLoading,
              currentAlertError: alertsProvider.errorMessage,
              historyError: alertsProvider.historyErrorMessage,
            );

            return Column(
              children: [
                // Primary status card with location selector
                const PrimaryStatusCard(),

                // Error indicator (shown when there's an error)
                if (model.errorBanner != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: AppTheme.errorIndicatorColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          model.errorBanner!.message,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorIndicatorColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Secondary locations row (if >1 saved location)
                if (model.secondaryLocationChips.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SecondaryLocationsRow(
                      items: model.secondaryLocationChips,
                    ),
                  ),

                // Nationwide summary (if active alerts)
                NationwideSummary(summary: model.nationwideSummary),

                // Recent alerts list header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppTheme.dividerColor(context),
                          endIndent: 8,
                        ),
                      ),
                      Text(
                        AppStrings.recentAlerts,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.mutedTextColor(context),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppTheme.dividerColor(context),
                          indent: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                if (model.showLastHourLabel)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      AppStrings.showingLastHour,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtleTextColor(context),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Alerts list (scrollable) - handles loading, offline, and content states
                Expanded(child: _buildAlertsList(model.history)),
              ],
            );
          },
    );
  }

  Widget _buildAlertsList(StatusHistoryModel model) {
    switch (model.state) {
      case StatusHistoryState.loading:
        return LoadingStatePlaceholder(message: model.message!);
      case StatusHistoryState.empty:
        return ContentStatePlaceholder(
          icon: model.icon!,
          message: model.message!,
          iconColor: Colors.green.shade300,
        );
      case StatusHistoryState.offline:
      case StatusHistoryState.noLocations:
      case StatusHistoryState.currentAlertError:
      case StatusHistoryState.historyError:
        return ContentStatePlaceholder(
          icon: model.icon!,
          message: model.message!,
        );
      case StatusHistoryState.data:
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: model.displayCount + (model.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < model.displayCount) {
              return AlertListItem(alert: model.alerts[index]);
            } else {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: TextButton(
                    onPressed: _loadMore,
                    child: const Text(AppStrings.loadMore),
                  ),
                ),
              );
            }
          },
        );
    }
  }
}
