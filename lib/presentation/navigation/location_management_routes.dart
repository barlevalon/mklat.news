import 'package:flutter/material.dart';

import '../../data/models/saved_location.dart';
import '../screens/add_location_screen.dart';
import '../screens/edit_location_screen.dart';

class LocationManagementRoutes {
  const LocationManagementRoutes._();

  static void openAddLocation(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddLocationScreen()),
    );
  }

  static void openEditLocation(BuildContext context, SavedLocation location) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditLocationScreen(location: location),
      ),
    );
  }
}
