import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import 'package:provider/provider.dart';
import '../../core/app_theme.dart';
import '../../data/models/saved_location.dart';
import '../navigation/location_management_routes.dart';
import '../providers/location_provider.dart';
import '../widgets/content_state_placeholder.dart';

void showLocationManagementModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => const LocationManagementModal(),
  );
}

class LocationManagementModal extends StatelessWidget {
  const LocationManagementModal({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final locations = locationProvider.locations;
        final primaryLocation = locationProvider.primaryLocation;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Material(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          AppStrings.myLocations,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              LocationManagementRoutes.openAddLocation(context),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Flexible(
                    child: locations.isEmpty
                        ? _buildEmptyState(context)
                        : _buildLocationsList(
                            context,
                            locations,
                            primaryLocation,
                            locationProvider,
                          ),
                  ),
                  // Bottom add button
                  if (locations.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () =>
                              LocationManagementRoutes.openAddLocation(context),
                          child: const Text(AppStrings.addLocation),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: ContentStatePlaceholder(
        message: AppStrings.noSavedLocations,
        children: [
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => LocationManagementRoutes.openAddLocation(context),
            child: const Text(AppStrings.addFirstLocation),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationsList(
    BuildContext context,
    List<SavedLocation> locations,
    SavedLocation? primaryLocation,
    LocationProvider locationProvider,
  ) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: locations.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final location = locations[index];
        final isPrimary = location.id == primaryLocation?.id;

        return ListTile(
          leading: Icon(
            isPrimary ? Icons.star : Icons.radio_button_unchecked,
            color: isPrimary
                ? Colors.amber
                : AppTheme.placeholderColor(context),
          ),
          title: Text(
            location.displayLabel,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(location.orefName),
          onTap: () async {
            final result = await locationProvider.setPrimary(location.id);
            if (!context.mounted) return;

            switch (result) {
              case LocationCommandResult.success:
                Navigator.pop(context);
                break;
              case LocationCommandResult.duplicate:
              case LocationCommandResult.notFound:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.locationNotFound)),
                );
                break;
              case LocationCommandResult.persistFailed:
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text(AppStrings.saveLocationFailed)),
                );
                break;
            }
          },
          onLongPress: () =>
              LocationManagementRoutes.openEditLocation(context, location),
        );
      },
    );
  }
}
