import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/oref_location.dart';
import '../../data/models/saved_location.dart';
import '../providers/location_provider.dart';

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

  void _saveLocation(BuildContext context) {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('יש לבחור אזור')));
      return;
    }

    final locationProvider = context.read<LocationProvider>();

    // Check for duplicate
    if (locationProvider.locations.any(
      (l) => l.orefName == _selectedLocation!.name,
    )) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('מיקום זה כבר קיים ברשימה')));
      return;
    }

    final savedLocation = SavedLocation.create(
      orefName: _selectedLocation!.name,
      customLabel: _labelController.text.trim(),
      isPrimary: _setAsPrimary,
      shelterTimeSec: _selectedLocation!.shelterTimeSec,
    );

    locationProvider.addLocation(savedLocation);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('הוסף מיקום'),
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
                    'שם מותאם (לא חובה)',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      hintText: 'בית, עבודה...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search field
                  const Text(
                    'בחר אזור',
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
                      hintText: 'חיפוש...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location list
                  Expanded(
                    child: locationProvider.availableLocations.isEmpty
                        ? const Center(child: Text('טוען רשימת אזורים...'))
                        : filteredLocations.isEmpty
                        ? const Center(child: Text('לא נמצאו תוצאות'))
                        : ListView.builder(
                            itemCount: filteredLocations.length,
                            itemBuilder: (context, index) {
                              final location = filteredLocations[index];
                              final isSelected =
                                  _selectedLocation?.hashId == location.hashId;

                              return ListTile(
                                title: Text(location.name),
                                trailing: isSelected
                                    ? const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedLocation = location;
                                  });
                                },
                              );
                            },
                          ),
                  ),
                  // Set as primary checkbox
                  CheckboxListTile(
                    title: const Text('הגדר כמיקום ראשי'),
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
                      onPressed: () => _saveLocation(context),
                      child: const Text('שמור'),
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
