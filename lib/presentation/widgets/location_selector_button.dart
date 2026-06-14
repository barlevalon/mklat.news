import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
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
        final displayText =
            primaryLocation?.displayLabel ?? AppStrings.chooseArea;
        final foreground = Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withAlpha(220)
            : const Color(0xFF24313D);
        final borderColor = Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withAlpha(35)
            : AppTheme.hairline;

        return Material(
          color: AppTheme.statusCardSurface(context),
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onTap ?? () => showLocationManagementModal(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on_outlined, size: 20, color: foreground),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      displayText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.expand_more, size: 22, color: foreground),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
