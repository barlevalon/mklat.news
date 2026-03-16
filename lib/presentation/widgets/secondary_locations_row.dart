import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../providers/alerts_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/location_provider.dart';
import '../screens/location_management_modal.dart';

class SecondaryLocationsRow extends StatelessWidget {
  final Function(String locationName)? onLocationTap;

  const SecondaryLocationsRow({super.key, this.onLocationTap});

  Color _getDotColor(
    String locationName,
    AlertsProvider alertsProvider,
    bool isOffline,
  ) {
    if (isOffline) return AppTheme.dotGrey;
    if (alertsProvider.isLocationInActiveAlerts(locationName)) {
      return AppTheme.dotRed;
    }
    return AppTheme.dotGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<LocationProvider, AlertsProvider, ConnectivityProvider>(
      builder:
          (
            context,
            locationProvider,
            alertsProvider,
            connectivityProvider,
            child,
          ) {
            final secondaryLocations = locationProvider.secondaryLocations;
            final isOffline = connectivityProvider.isOffline;

            if (secondaryLocations.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: secondaryLocations.length,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  final location = secondaryLocations[index];
                  final dotColor = _getDotColor(
                    location.orefName,
                    alertsProvider,
                    isOffline,
                  );

                  return InkWell(
                    onTap: () {
                      if (onLocationTap != null) {
                        onLocationTap!.call(location.orefName);
                      } else {
                        showLocationManagementModal(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.12),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            location.displayLabel,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
    );
  }
}
