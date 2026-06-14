import 'package:flutter/material.dart';
import '../../core/app_strings.dart';
import '../../core/app_theme.dart';
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

    return ListView.separated(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      itemCount: filteredLocations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final location = filteredLocations[index];
        final isSelected = identical(_selectedLocation, location);

        return _LocationResultRow(
          key: ValueKey(
            '${location.id}:${location.hashId}:${location.name}:${location.areaId}',
          ),
          location: location,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              _selectedLocation = isSelected ? null : location;
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
          titleTextStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurface,
          ),
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
            final canSave =
                _selectedLocation != null && !locationProvider.isSaving;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: AppStrings.customLabelOptional),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.customLabelHint,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FieldLabel(label: AppStrings.chooseArea),
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
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: _buildLocationList(
                      context,
                      locationProvider,
                      filteredLocations,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.statusCardSurface(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.dividerColor(context)),
                    ),
                    child: CheckboxListTile(
                      title: const Text(AppStrings.setAsPrimary),
                      value: _setAsPrimary,
                      onChanged: (value) {
                        setState(() {
                          _setAsPrimary = value ?? false;
                        });
                      },
                      activeColor: AppTheme.statusGreen,
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: canSave ? () => _saveLocation(context) : null,
                      child: locationProvider.isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(AppStrings.save),
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

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: AppTheme.mutedTextColor(context),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _LocationResultRow extends StatelessWidget {
  final OrefLocation location;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationResultRow({
    super.key,
    required this.location,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppTheme.statusGreen
        : AppTheme.dividerColor(context);
    final backgroundColor = isSelected
        ? AppTheme.statusGreenTint
        : AppTheme.statusCardSurface(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            children: [
              if (isSelected)
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: AppTheme.statusGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                )
              else
                const SizedBox(width: 30, height: 30),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
