import 'package:flutter/material.dart';
import '../../core/app_theme.dart';
import '../models/status_presentation_model.dart';
import '../screens/location_management_modal.dart';

class SecondaryLocationsRow extends StatelessWidget {
  final List<SecondaryLocationChipModel> items;
  final Function(String locationName)? onLocationTap;

  const SecondaryLocationsRow({
    super.key,
    required this.items,
    this.onLocationTap,
  });

  Color _getDotColor(SecondaryLocationDotState state) {
    switch (state) {
      case SecondaryLocationDotState.unavailable:
        return AppTheme.dotGrey;
      case SecondaryLocationDotState.active:
        return AppTheme.dotRed;
      case SecondaryLocationDotState.inactive:
        return AppTheme.dotGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final item = items[index];
          final dotColor = _getDotColor(item.dotState);

          return InkWell(
            onTap: () {
              if (onLocationTap != null) {
                onLocationTap!.call(item.orefName);
              } else {
                showLocationManagementModal(context);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
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
                    item.label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
