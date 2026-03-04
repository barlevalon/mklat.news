import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/data/models/saved_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationProvider', () {
    late LocationProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = LocationProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state: empty locations, not loaded', () {
      expect(provider.locations, isEmpty);
      expect(provider.isLoaded, isFalse);
      expect(provider.primaryLocation, isNull);
      expect(provider.secondaryLocations, isEmpty);
    });

    test('loadLocations: loads from SharedPreferences', () async {
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        customLabel: 'בית',
        isPrimary: true,
      );
      final jsonStr = jsonEncode([location.toJson()]);
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations': jsonStr,
      });

      final newProvider = LocationProvider();
      await newProvider.loadLocations();

      expect(newProvider.isLoaded, isTrue);
      expect(newProvider.locations.length, 1);
      expect(newProvider.primaryLocation?.orefName, 'תל אביב');
    });

    test('addLocation: adds and persists', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        customLabel: 'בית',
      );

      await provider.addLocation(location);

      expect(provider.locations.length, 1);
      expect(provider.locations.first.orefName, 'תל אביב');

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('mklat_saved_locations');
      expect(saved, isNotNull);
      expect(saved, contains('תל אביב'));
    });

    test('addLocation: prevents duplicate orefNames', () async {
      await provider.loadLocations();
      final location1 = SavedLocation.create(orefName: 'תל אביב');
      final location2 = SavedLocation.create(orefName: 'תל אביב');

      await provider.addLocation(location1);
      await provider.addLocation(location2);

      expect(provider.locations.length, 1);
    });

    test('addLocation: first location auto-promoted to primary', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        isPrimary: false,
      );

      await provider.addLocation(location);

      expect(provider.primaryLocation, isNotNull);
      expect(provider.primaryLocation!.isPrimary, isTrue);
    });

    test('addLocation with isPrimary: clears other primaries', () async {
      await provider.loadLocations();
      final location1 = SavedLocation.create(
        orefName: 'תל אביב',
        isPrimary: true,
      );
      final location2 = SavedLocation.create(
        orefName: 'ירושלים',
        isPrimary: true,
      );

      await provider.addLocation(location1);
      await provider.addLocation(location2);

      expect(provider.locations.where((l) => l.isPrimary).length, 1);
      expect(provider.primaryLocation?.orefName, 'ירושלים');
    });

    test('updateLocation: updates and persists', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        customLabel: 'בית',
      );
      await provider.addLocation(location);

      final updated = location.copyWith(customLabel: 'עבודה');
      await provider.updateLocation(updated);

      expect(provider.locations.first.customLabel, 'עבודה');
    });

    test('deleteLocation: removes and persists', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(orefName: 'תל אביב');
      await provider.addLocation(location);

      await provider.deleteLocation(location.id);

      expect(provider.locations, isEmpty);
    });

    test(
      'deleteLocation: if primary deleted, promotes first remaining',
      () async {
        await provider.loadLocations();
        final location1 = SavedLocation.create(
          orefName: 'תל אביב',
          isPrimary: true,
        );
        final location2 = SavedLocation.create(
          orefName: 'ירושלים',
          isPrimary: false,
        );

        await provider.addLocation(location1);
        await provider.addLocation(location2);
        await provider.deleteLocation(location1.id);

        expect(provider.primaryLocation?.orefName, 'ירושלים');
        expect(provider.primaryLocation?.isPrimary, isTrue);
      },
    );

    test('setPrimary: updates isPrimary flags', () async {
      await provider.loadLocations();
      final location1 = SavedLocation.create(
        orefName: 'תל אביב',
        isPrimary: true,
      );
      final location2 = SavedLocation.create(
        orefName: 'ירושלים',
        isPrimary: false,
      );

      await provider.addLocation(location1);
      await provider.addLocation(location2);
      await provider.setPrimary(location2.id);

      expect(provider.primaryLocation?.id, location2.id);
      expect(provider.locations.where((l) => l.isPrimary).length, 1);
    });

    test(
      'primaryLocation getter: returns primary, falls back to first',
      () async {
        await provider.loadLocations();
        final location1 = SavedLocation.create(
          orefName: 'תל אביב',
          isPrimary: false,
        );
        final location2 = SavedLocation.create(
          orefName: 'ירושלים',
          isPrimary: false,
        );

        await provider.addLocation(location1);
        await provider.addLocation(location2);

        // Neither is marked primary, should fall back to first
        expect(provider.primaryLocation?.orefName, 'תל אביב');
      },
    );

    test('secondaryLocations: returns non-primary locations', () async {
      await provider.loadLocations();
      final location1 = SavedLocation.create(
        orefName: 'תל אביב',
        isPrimary: true,
      );
      final location2 = SavedLocation.create(
        orefName: 'ירושלים',
        isPrimary: false,
      );
      final location3 = SavedLocation.create(
        orefName: 'חיפה',
        isPrimary: false,
      );

      await provider.addLocation(location1);
      await provider.addLocation(location2);
      await provider.addLocation(location3);

      expect(provider.secondaryLocations.length, 2);
      expect(
        provider.secondaryLocations.map((l) => l.orefName).toList(),
        containsAll(['ירושלים', 'חיפה']),
      );
    });
  });
}
