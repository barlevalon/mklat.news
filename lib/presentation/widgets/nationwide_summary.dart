import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/alerts_provider.dart';
import '../providers/location_provider.dart';

class NationwideSummary extends StatelessWidget {
  const NationwideSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AlertsProvider, LocationProvider>(
      builder: (context, alertsProvider, locationProvider, child) {
        final nationwideCount = alertsProvider.nationwideAlertCount;

        if (nationwideCount == 0) {
          return const SizedBox.shrink();
        }

        final savedLocationNames = locationProvider.locations
            .map((l) => l.orefName)
            .toList();
        final userLocationCount = alertsProvider.userLocationAlertCount(
          savedLocationNames,
        );

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning_amber,
                size: 16,
                color: Colors.orange.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                '$userLocationCount באזורים שלך • $nationwideCount ברחבי הארץ',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
