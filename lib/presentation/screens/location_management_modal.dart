import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/saved_location.dart';
import '../providers/location_provider.dart';
import 'add_location_screen.dart';
import 'edit_location_screen.dart';

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
                          'המיקומים שלי',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddLocationScreen(),
                              ),
                            );
                          },
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
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddLocationScreen(),
                              ),
                            );
                          },
                          child: const Text('הוסף מיקום'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'אין מיקומים שמורים',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddLocationScreen(),
                ),
              );
            },
            child: const Text('הוסף מיקום ראשון'),
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
            color: isPrimary ? Colors.amber : Colors.grey,
          ),
          title: Text(
            location.displayLabel,
            style: TextStyle(
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(location.orefName),
          onTap: () {
            locationProvider.setPrimary(location.id);
            Navigator.pop(context);
          },
          onLongPress: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EditLocationScreen(location: location),
              ),
            );
          },
        );
      },
    );
  }
}
