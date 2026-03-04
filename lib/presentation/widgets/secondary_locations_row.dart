import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../providers/alerts_provider.dart';
import '../providers/location_provider.dart';
import '../screens/location_management_modal.dart';

class SecondaryLocationsRow extends StatelessWidget {
  final Function(String locationName)? onLocationTap;

  const SecondaryLocationsRow({super.key, this.onLocationTap});

  Color _getDotColor(String locationName, AlertsProvider alertsProvider) {
    if (alertsProvider.isLocationInActiveAlerts(locationName)) {
      return AppTheme.dotRed;
    }
    return AppTheme.dotGreen;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocationProvider, AlertsProvider>(
      builder: (context, locationProvider, alertsProvider, child) {
        final secondaryLocations = locationProvider.secondaryLocations;

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
              final dotColor = _getDotColor(location.orefName, alertsProvider);

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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.black12, width: 1),
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
