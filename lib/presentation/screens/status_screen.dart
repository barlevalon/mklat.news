import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../data/models/alert.dart';
import '../../domain/alert_state_machine.dart';
import '../providers/alerts_provider.dart';
import '../providers/location_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/primary_status_card.dart';
import '../widgets/secondary_locations_row.dart';
import '../widgets/nationwide_summary.dart';
import '../widgets/alert_list_item.dart';

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

  List<Alert> _getFilteredAlerts(
    AlertsProvider alertsProvider,
    LocationProvider locationProvider,
  ) {
    final savedLocationNames = locationProvider.locations
        .map((l) => l.orefName)
        .toSet();

    if (savedLocationNames.isEmpty) {
      return [];
    }

    return alertsProvider.alertHistory.where((alert) {
      return savedLocationNames.any(
        (name) => AlertStateMachine.locationsMatch(alert.location, name),
      );
    }).toList();
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
            final hasLocations = locationProvider.locations.isNotEmpty;
            final isOffline = connectivityProvider.isOffline;
            final filteredAlerts = _getFilteredAlerts(
              alertsProvider,
              locationProvider,
            );
            final displayCount = filteredAlerts.length < _displayedItemCount
                ? filteredAlerts.length
                : _displayedItemCount;
            final hasMore = filteredAlerts.length > displayCount;

            return Column(
              children: [
                // Primary status card with location selector
                const PrimaryStatusCard(),

                // Error indicator (shown when there's an error)
                if (alertsProvider.errorMessage != null)
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
                          alertsProvider.errorMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.errorIndicatorColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Secondary locations row (if >1 saved location)
                if (locationProvider.secondaryLocations.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SecondaryLocationsRow(),
                  ),

                // Nationwide summary (if active alerts)
                const NationwideSummary(),

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
                        'התרעות אחרונות',
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
                if (!isOffline && filteredAlerts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'מציג שעה אחרונה',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.subtleTextColor(context),
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                // Alerts list (scrollable) - handles loading, offline, and content states
                Expanded(
                  child: _buildAlertsList(
                    hasLocations,
                    isOffline,
                    alertsProvider,
                    filteredAlerts,
                    displayCount,
                    hasMore,
                  ),
                ),
              ],
            );
          },
    );
  }

  Widget _buildAlertsList(
    bool hasLocations,
    bool isOffline,
    AlertsProvider alertsProvider,
    List<Alert> filteredAlerts,
    int displayCount,
    bool hasMore,
  ) {
    // Offline state: show waiting message instead of cached data
    if (isOffline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.signal_wifi_off,
              size: 48,
              color: AppTheme.placeholderIconColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'ממתין לחיבור לאינטרנט...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.placeholderColor(context),
              ),
            ),
          ],
        ),
      );
    }

    // Loading state: show spinner when loading and no data yet
    if (alertsProvider.isLoading && filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'טוען...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.placeholderColor(context),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasLocations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: AppTheme.placeholderIconColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              'הוסף מיקום כדי לראות התרעות',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.placeholderColor(context),
              ),
            ),
          ],
        ),
      );
    }

    if (filteredAlerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 48, color: Colors.green.shade300),
            const SizedBox(height: 16),
            Text(
              'אין התרעות באזורים שלך',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.placeholderColor(context),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: displayCount + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < displayCount) {
          return AlertListItem(alert: filteredAlerts[index]);
        } else {
          // Load more button
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton(
                onPressed: _loadMore,
                child: const Text('טען עוד'),
              ),
            ),
          );
        }
      },
    );
  }
}
