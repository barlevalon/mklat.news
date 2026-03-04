import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/location_provider.dart';
import '../screens/location_management_modal.dart';

class LocationSelectorButton extends StatelessWidget {
  final VoidCallback? onTap;

  const LocationSelectorButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final primaryLocation = locationProvider.primaryLocation;
        final displayText = primaryLocation?.displayLabel ?? 'בחר אזור';

        return GestureDetector(
          onTap: onTap ?? () => showLocationManagementModal(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  displayText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: Colors.black54,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
