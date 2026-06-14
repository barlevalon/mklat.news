import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import 'package:provider/provider.dart';
import '../../data/models/oref_location.dart';
import '../../data/models/saved_location.dart';
import '../providers/location_provider.dart';
import '../widgets/content_state_placeholder.dart';

class AddLocationScreen extends StatefulWidget {
  const AddLocationScreen({super.key});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _labelController = TextEditingController();
  final _searchController = TextEditingController();
  OrefLocation? _selectedLocation;
  bool _setAsPrimary = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _labelController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<OrefLocation> _getFilteredLocations(
    List<OrefLocation> availableLocations,
  ) {
    if (_searchQuery.isEmpty) {
      return availableLocations;
    }
    return availableLocations.where((location) {
      return location.name.contains(_searchQuery);
    }).toList();
  }

  Future<void> _saveLocation(BuildContext context) async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.chooseAreaRequired)),
      );
      return;
    }

    final locationProvider = context.read<LocationProvider>();
    final savedLocation = SavedLocation.create(
      orefName: _selectedLocation!.name,
      customLabel: _labelController.text.trim(),
      isPrimary: _setAsPrimary,
      shelterTimeSec: _selectedLocation!.shelterTimeSec,
    );

    final result = await locationProvider.addLocation(savedLocation);
    if (!context.mounted) return;

    switch (result) {
      case AddLocationResult.success:
        Navigator.pop(context);
        break;
      case AddLocationResult.duplicate:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.duplicateLocation)),
        );
        break;
      case AddLocationResult.persistFailed:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(AppStrings.saveLocationFailed)),
        );
        break;
    }
  }

  Widget _buildLocationList(
    BuildContext context,
    LocationProvider locationProvider,
    List<OrefLocation> filteredLocations,
  ) {
    if (locationProvider.isLoadingAvailableLocations) {
      return const LoadingStatePlaceholder(
        message: AppStrings.loadingLocations,
      );
    }

    final errorMessage = locationProvider.availableLocationsErrorMessage;
    if (errorMessage != null) {
      return ContentStatePlaceholder(
        icon: Icons.error_outline,
        message: errorMessage,
        iconColor: Theme.of(context).colorScheme.error,
        textColor: Theme.of(context).colorScheme.error,
        children: const [SizedBox(height: 8), Text(AppStrings.tryAgainLater)],
      );
    }

    if (filteredLocations.isEmpty) {
      return const ContentStatePlaceholder(message: AppStrings.noResults);
    }

    return ListView.builder(
      itemCount: filteredLocations.length,
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final isSelected = identical(_selectedLocation, location);

        return ListTile(
          key: ValueKey(
            '${location.id}:${location.hashId}:${location.name}:${location.areaId}',
          ),
          title: Text(location.name),
          trailing: isSelected
              ? const Icon(Icons.check, color: Colors.green)
              : null,
          onTap: () {
            setState(() {
              _selectedLocation = location;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(AppStrings.addLocation),
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ),
        body: Consumer<LocationProvider>(
          builder: (context, locationProvider, child) {
            final filteredLocations = _getFilteredLocations(
              locationProvider.availableLocations,
            );

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Custom label field
                  const Text(
                    AppStrings.customLabelOptional,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.customLabelHint,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search field
                  const Text(
                    AppStrings.chooseArea,
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: AppStrings.searchHint,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location list
                  Expanded(
                    child: _buildLocationList(
                      context,
                      locationProvider,
                      filteredLocations,
                    ),
                  ),
                  // Set as primary checkbox
                  CheckboxListTile(
                    title: const Text(AppStrings.setAsPrimary),
                    value: _setAsPrimary,
                    onChanged: (value) {
                      setState(() {
                        _setAsPrimary = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  const SizedBox(height: 16),
                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: locationProvider.isSaving
                          ? null
                          : () => _saveLocation(context),
                      child: const Text(AppStrings.save),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
