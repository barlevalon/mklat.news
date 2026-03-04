import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../data/models/saved_location.dart';

class LocationProvider extends ChangeNotifier {
  List<SavedLocation> _locations = [];
  bool _isLoaded = false;

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  bool get isLoaded => _isLoaded;

  SavedLocation? get primaryLocation {
    try {
      return _locations.firstWhere((l) => l.isPrimary);
    } catch (_) {
      return _locations.isNotEmpty ? _locations.first : null;
    }
  }

  List<SavedLocation> get secondaryLocations {
    final primary = primaryLocation;
    if (primary == null) return [];
    return _locations.where((l) => l.id != primary.id).toList();
  }

  /// Load saved locations from SharedPreferences.
  /// Call once on app start.
  Future<void> loadLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(AppConstants.savedLocationsKey);
      if (jsonStr != null) {
        final list = jsonDecode(jsonStr) as List;
        _locations = list
            .whereType<Map<String, dynamic>>()
            .map((e) => SavedLocation.fromJson(e))
            .toList();
      }
    } catch (e) {
      _locations = [];
    }
    _isLoaded = true;
    notifyListeners();
  }

  /// Add a new location.
  Future<void> addLocation(SavedLocation location) async {
    // Prevent duplicates by orefName
    if (_locations.any((l) => l.orefName == location.orefName)) return;

    // If setting as primary, clear other primaries
    if (location.isPrimary) {
      _locations = _locations
          .map((l) => l.isPrimary ? l.copyWith(isPrimary: false) : l)
          .toList();
    }

    // If first location, make it primary
    if (_locations.isEmpty) {
      location = location.copyWith(isPrimary: true);
    }

    _locations.add(location);
    await _persist();
    notifyListeners();
  }

  /// Update an existing location.
  Future<void> updateLocation(SavedLocation updated) async {
    final index = _locations.indexWhere((l) => l.id == updated.id);
    if (index == -1) return;

    // If setting as primary, clear other primaries
    if (updated.isPrimary) {
      _locations = _locations
          .map((l) => l.isPrimary ? l.copyWith(isPrimary: false) : l)
          .toList();
    }

    _locations[index] = updated;
    await _persist();
    notifyListeners();
  }

  /// Delete a location by ID.
  Future<void> deleteLocation(String id) async {
    final wasPrimary = _locations.any((l) => l.id == id && l.isPrimary);
    _locations.removeWhere((l) => l.id == id);

    // If deleted location was primary, promote the first remaining
    if (wasPrimary && _locations.isNotEmpty) {
      _locations[0] = _locations[0].copyWith(isPrimary: true);
    }

    await _persist();
    notifyListeners();
  }

  /// Set a location as primary by ID.
  Future<void> setPrimary(String id) async {
    _locations = _locations
        .map((l) => l.copyWith(isPrimary: l.id == id))
        .toList();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(_locations.map((l) => l.toJson()).toList());
      await prefs.setString(AppConstants.savedLocationsKey, jsonStr);
    } catch (e) {
      // Persistence failure is non-fatal
    }
  }
}
