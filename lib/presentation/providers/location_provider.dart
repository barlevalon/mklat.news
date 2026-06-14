import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import '../../core/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_constants.dart';
import '../../data/models/saved_location.dart';
import '../../data/models/oref_location.dart';
import '../../data/services/oref_districts_service.dart';
import '../../domain/saved_locations.dart';

enum AddLocationResult { success, duplicate, persistFailed }

enum UpdateLocationResult { success, notFound, persistFailed }

enum DeleteLocationResult { success, notFound, persistFailed }

enum SetPrimaryLocationResult { success, notFound, persistFailed }

typedef PersistSavedLocations =
    Future<bool> Function(List<SavedLocation> locations);

class LocationProvider extends ChangeNotifier {
  LocationProvider({@visibleForTesting PersistSavedLocations? persistLocations})
    : _persistLocationsForTest = persistLocations;

  final PersistSavedLocations? _persistLocationsForTest;
  Future<void> _locationMutationQueue = Future.value();
  int _pendingLocationMutations = 0;

  List<SavedLocation> _locations = [];
  bool _isLoaded = false;
  List<OrefLocation> _availableLocations = [];
  bool _isLoadingAvailableLocations = true;
  String? _availableLocationsErrorMessage;

  List<SavedLocation> get locations => List.unmodifiable(_locations);
  bool get isLoaded => _isLoaded;
  List<OrefLocation> get availableLocations =>
      List.unmodifiable(_availableLocations);
  bool get isLoadingAvailableLocations => _isLoadingAvailableLocations;
  bool get isSaving => _pendingLocationMutations > 0;
  String? get availableLocationsErrorMessage => _availableLocationsErrorMessage;

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
  Future<AddLocationResult> addLocation(SavedLocation location) {
    return _mutateLocations(() async {
      // Prevent duplicates by orefName
      if (_locations.any((l) => l.orefName == location.orefName)) {
        return AddLocationResult.duplicate;
      }

      final existing = location.isPrimary
          ? _locations.map((l) => l.copyWith(isPrimary: false)).toList()
          : _locations;
      final didSave = await _saveAndPublish([...existing, location]);
      return didSave
          ? AddLocationResult.success
          : AddLocationResult.persistFailed;
    });
  }

  /// Update an existing location.
  Future<UpdateLocationResult> updateLocation(SavedLocation updated) {
    return _mutateLocations(() async {
      final index = _locations.indexWhere((l) => l.id == updated.id);
      if (index == -1) return UpdateLocationResult.notFound;

      final next = updated.isPrimary
          ? _locations.map((l) => l.copyWith(isPrimary: false)).toList()
          : [..._locations];
      next[index] = updated;
      final didSave = await _saveAndPublish(next);
      return didSave
          ? UpdateLocationResult.success
          : UpdateLocationResult.persistFailed;
    });
  }

  /// Delete a location by ID.
  Future<DeleteLocationResult> deleteLocation(String id) {
    return _mutateLocations(() async {
      final next = _locations.where((l) => l.id != id).toList();
      if (next.length == _locations.length) {
        return DeleteLocationResult.notFound;
      }

      final didSave = await _saveAndPublish(next);
      return didSave
          ? DeleteLocationResult.success
          : DeleteLocationResult.persistFailed;
    });
  }

  /// Set a location as primary by ID.
  Future<SetPrimaryLocationResult> setPrimary(String id) {
    return _mutateLocations(() async {
      if (!_locations.any((l) => l.id == id)) {
        return SetPrimaryLocationResult.notFound;
      }

      final next = _locations
          .map((l) => l.copyWith(isPrimary: l.id == id))
          .toList();
      final didSave = await _saveAndPublish(next);
      return didSave
          ? SetPrimaryLocationResult.success
          : SetPrimaryLocationResult.persistFailed;
    });
  }

  Future<T> _mutateLocations<T>(Future<T> Function() mutation) {
    _pendingLocationMutations += 1;
    notifyListeners();

    final result = _locationMutationQueue.then((_) => mutation());
    _locationMutationQueue = result.then<void>((_) {}, onError: (_) {});

    return result.whenComplete(() {
      _pendingLocationMutations -= 1;
      notifyListeners();
    });
  }

  Future<bool> _saveAndPublish(List<SavedLocation> next) async {
    final normalized = normalizeSavedLocations(next);
    final didPersist = await _persistLocations(normalized);
    if (!didPersist) return false;

    _locations = normalized;
    notifyListeners();
    return true;
  }

  Future<bool> _persistLocations(List<SavedLocation> locations) async {
    final persistForTest = _persistLocationsForTest;
    if (persistForTest != null) {
      return persistForTest(locations);
    }

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
    _isLoadingAvailableLocations = true;
    _availableLocationsErrorMessage = null;
    notifyListeners();

    try {
      final locations = await districtsService.fetchDistricts();
      locations.sort((a, b) => a.name.compareTo(b.name));
      _availableLocations = locations;
      _availableLocationsErrorMessage = locations.isEmpty
          ? AppStrings.loadLocationsError
          : null;
    } catch (e) {
      _availableLocations = [];
      _availableLocationsErrorMessage = AppStrings.loadLocationsError;
    }

    _isLoadingAvailableLocations = false;
    notifyListeners();
  }

  /// Test helper to set available locations directly.
  @visibleForTesting
  void loadAvailableLocationsForTest(List<OrefLocation> locations) {
    _availableLocations = locations;
    _isLoadingAvailableLocations = false;
    _availableLocationsErrorMessage = null;
    notifyListeners();
  }

  /// Test helper to simulate a completed catalog load failure.
  @visibleForTesting
  void markAvailableLocationsFailedForTest() {
    _availableLocations = [];
    _isLoadingAvailableLocations = false;
    _availableLocationsErrorMessage = AppStrings.loadLocationsError;
    notifyListeners();
  }
}
