import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../data/models/saved_location.dart';
import '../../data/models/oref_location.dart';
import '../../data/services/oref_districts_service.dart';
import '../../domain/saved_locations.dart';

class LocationProvider extends ChangeNotifier {
  List<SavedLocation> _locations = [];
  bool _isLoaded = false;
  List<OrefLocation> _availableLocations = [];

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  bool get isLoaded => _isLoaded;
  List<OrefLocation> get availableLocations =>
      List.unmodifiable(_availableLocations);

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
        _locations = normalizeSavedLocations(
          list
              .whereType<Map<String, dynamic>>()
              .map((e) => SavedLocation.fromJson(e))
              .toList(),
        );
        await _persistLocations(_locations);
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

    final existing = location.isPrimary
        ? _locations.map((l) => l.copyWith(isPrimary: false)).toList()
        : _locations;
    await _saveAndPublish([...existing, location]);
  }

  /// Update an existing location.
  Future<void> updateLocation(SavedLocation updated) async {
    final index = _locations.indexWhere((l) => l.id == updated.id);
    if (index == -1) return;

    final next = updated.isPrimary
        ? _locations.map((l) => l.copyWith(isPrimary: false)).toList()
        : [..._locations];
    next[index] = updated;
    await _saveAndPublish(next);
  }

  /// Delete a location by ID.
  Future<void> deleteLocation(String id) async {
    final next = _locations.where((l) => l.id != id).toList();
    if (next.length == _locations.length) return;

    await _saveAndPublish(next);
  }

  /// Set a location as primary by ID.
  Future<void> setPrimary(String id) async {
    if (!_locations.any((l) => l.id == id)) return;

    final next = _locations
        .map((l) => l.copyWith(isPrimary: l.id == id))
        .toList();
    await _saveAndPublish(next);
  }

  Future<void> _saveAndPublish(List<SavedLocation> next) async {
    final normalized = normalizeSavedLocations(next);
    final didPersist = await _persistLocations(normalized);
    if (!didPersist) return;

    _locations = normalized;
    notifyListeners();
  }

  Future<bool> _persistLocations(List<SavedLocation> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = jsonEncode(locations.map((l) => l.toJson()).toList());
      return prefs.setString(AppConstants.savedLocationsKey, jsonStr);
    } catch (e) {
      return false;
    }
  }

  Future<void> loadAvailableLocations(
    OrefDistrictsService districtsService,
  ) async {
    try {
      _availableLocations = await districtsService.fetchDistricts();
      // Sort alphabetically by Hebrew name
      _availableLocations.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    } catch (e) {
      // Non-fatal, list stays empty
    }
  }

  /// Test helper to set available locations directly.
  @visibleForTesting
  void loadAvailableLocationsForTest(List<OrefLocation> locations) {
    _availableLocations = locations;
    notifyListeners();
  }
}
