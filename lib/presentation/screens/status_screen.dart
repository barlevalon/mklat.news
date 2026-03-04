import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/alert.dart';
import '../../domain/alert_state_machine.dart';
import '../providers/alerts_provider.dart';
import '../providers/location_provider.dart';
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
    return Consumer2<AlertsProvider, LocationProvider>(
      builder: (context, alertsProvider, locationProvider, child) {
        final hasLocations = locationProvider.locations.isNotEmpty;
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
                    child: Divider(color: Colors.grey.shade300, endIndent: 8),
                  ),
                  Text(
                    'התרעות אחרונות',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                  Expanded(
                    child: Divider(color: Colors.grey.shade300, indent: 8),
                  ),
                ],
              ),
            ),

            // Alerts list (scrollable)
            Expanded(
              child: _buildAlertsList(
                hasLocations,
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
    List<Alert> filteredAlerts,
    int displayCount,
    bool hasMore,
  ) {
    if (!hasLocations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'הוסף מיקום כדי לראות התרעות',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
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
