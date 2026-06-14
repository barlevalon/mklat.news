import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/data/models/oref_location.dart';
import 'package:mklat/data/models/saved_location.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_districts_service.dart';
import 'package:mklat/presentation/providers/location_provider.dart';

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
      expect(provider.availableLocations, isEmpty);
      expect(provider.isLoadingAvailableLocations, isTrue);
      expect(provider.availableLocationsErrorMessage, isNull);
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

    test('loadLocations: normalizes persisted locations', () async {
      final location1 = SavedLocation.create(
        orefName: 'תל אביב',
        isPrimary: false,
      );
      final location2 = SavedLocation.create(
        orefName: 'ירושלים',
        isPrimary: false,
      );
      final jsonStr = jsonEncode([location1.toJson(), location2.toJson()]);
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations': jsonStr,
      });

      final newProvider = LocationProvider();
      await newProvider.loadLocations();

      expect(newProvider.primaryLocation?.orefName, 'תל אביב');
      expect(newProvider.locations.where((l) => l.isPrimary), hasLength(1));
    });

    test('addLocation: adds and persists', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        customLabel: 'בית',
      );

      final result = await provider.addLocation(location);

      expect(result, AddLocationResult.success);
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

      final result1 = await provider.addLocation(location1);
      final result2 = await provider.addLocation(location2);

      expect(result1, AddLocationResult.success);
      expect(result2, AddLocationResult.duplicate);
      expect(provider.locations.length, 1);
    });

    test('addLocation: persist failure does not publish state', () async {
      provider.dispose();
      provider = LocationProvider(persistLocations: (_) async => false);
      await provider.loadLocations();

      final result = await provider.addLocation(
        SavedLocation.create(orefName: 'תל אביב'),
      );

      expect(result, AddLocationResult.persistFailed);
      expect(provider.locations, isEmpty);
      expect(provider.isSaving, isFalse);
    });

    test(
      'location mutations serialize against latest published state',
      () async {
        provider.dispose();
        final persistCompleters = <Completer<bool>>[];
        final persistedSnapshots = <List<String>>[];
        provider = LocationProvider(
          persistLocations: (locations) {
            persistedSnapshots.add(
              locations.map((location) => location.orefName).toList(),
            );
            final completer = Completer<bool>();
            persistCompleters.add(completer);
            return completer.future;
          },
        );
        await provider.loadLocations();

        final first = provider.addLocation(
          SavedLocation.create(orefName: 'חיפה'),
        );
        final second = provider.addLocation(
          SavedLocation.create(orefName: 'ירושלים'),
        );
        await pumpEventQueue();

        expect(provider.isSaving, isTrue);
        expect(persistCompleters, hasLength(1));
        expect(persistedSnapshots.single, ['חיפה']);

        persistCompleters.first.complete(true);
        expect(await first, AddLocationResult.success);
        await pumpEventQueue();

        expect(persistCompleters, hasLength(2));
        expect(persistedSnapshots.last, ['חיפה', 'ירושלים']);

        persistCompleters.last.complete(true);
        expect(await second, AddLocationResult.success);

        expect(provider.locations.map((location) => location.orefName), [
          'חיפה',
          'ירושלים',
        ]);
        expect(provider.isSaving, isFalse);
      },
    );

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

    test('updateLocation: updates and preserves one primary', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(
        orefName: 'תל אביב',
        customLabel: 'בית',
      );
      await provider.addLocation(location);

      final updated = location.copyWith(customLabel: 'עבודה');
      final result = await provider.updateLocation(updated);

      expect(result, UpdateLocationResult.success);
      expect(provider.locations.first.customLabel, 'עבודה');
      expect(provider.locations.where((l) => l.isPrimary), hasLength(1));
      expect(provider.primaryLocation?.id, location.id);
    });

    test('updateLocation: missing id reports not found', () async {
      await provider.loadLocations();
      final missing = SavedLocation.create(orefName: 'תל אביב');

      final result = await provider.updateLocation(missing);

      expect(result, UpdateLocationResult.notFound);
      expect(provider.locations, isEmpty);
    });

    test('deleteLocation: removes and persists', () async {
      await provider.loadLocations();
      final location = SavedLocation.create(orefName: 'תל אביב');
      await provider.addLocation(location);

      final result = await provider.deleteLocation(location.id);

      expect(result, DeleteLocationResult.success);
      expect(provider.locations, isEmpty);
    });

    test('deleteLocation: missing id reports not found', () async {
      await provider.loadLocations();

      final result = await provider.deleteLocation('missing');

      expect(result, DeleteLocationResult.notFound);
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
      final result = await provider.setPrimary(location2.id);

      expect(result, SetPrimaryLocationResult.success);
      expect(provider.primaryLocation?.id, location2.id);
      expect(provider.locations.where((l) => l.isPrimary).length, 1);
    });

    test('setPrimary: missing id leaves existing primary unchanged', () async {
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
      final result = await provider.setPrimary('missing');

      expect(result, SetPrimaryLocationResult.notFound);
      expect(provider.primaryLocation?.id, location1.id);
      expect(provider.locations.where((l) => l.isPrimary), hasLength(1));
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

    test(
      'loadAvailableLocations: stores sorted catalog and clears loading',
      () async {
        final districtsService = OrefDistrictsService(
          HttpClient(
            client: MockClient(
              (_) async => http.Response.bytes(
                utf8.encode(
                  '[{"label_he":"ירושלים","value":"hash2","id":"2","areaid":2,"areaname":"ירושלים","migun_time":60},'
                  '{"label_he":"אבו גוש","value":"hash1","id":"1","areaid":1,"areaname":"בית שמש","migun_time":90}]',
                ),
                200,
              ),
            ),
          ),
        );

        await provider.loadAvailableLocations(districtsService);

        expect(provider.isLoadingAvailableLocations, isFalse);
        expect(provider.availableLocationsErrorMessage, isNull);
        expect(provider.availableLocations.map((location) => location.name), [
          'אבו גוש',
          'ירושלים',
        ]);
      },
    );

    test(
      'loadAvailableLocations: empty catalog stops loading and sets error',
      () async {
        final districtsService = OrefDistrictsService(
          HttpClient(client: MockClient((_) async => http.Response('[]', 200))),
        );

        await provider.loadAvailableLocations(districtsService);

        expect(provider.isLoadingAvailableLocations, isFalse);
        expect(provider.availableLocations, isEmpty);
        expect(
          provider.availableLocationsErrorMessage,
          'שגיאה בטעינת רשימת אזורים',
        );
      },
    );

    test(
      'loadAvailableLocations: thrown error stops loading and sets error',
      () async {
        await provider.loadAvailableLocations(ThrowingDistrictsService());

        expect(provider.isLoadingAvailableLocations, isFalse);
        expect(provider.availableLocations, isEmpty);
        expect(
          provider.availableLocationsErrorMessage,
          'שגיאה בטעינת רשימת אזורים',
        );
      },
    );

    test(
      'loadAvailableLocationsForTest: marks catalog loaded successfully',
      () {
        provider.loadAvailableLocationsForTest([
          const OrefLocation(
            name: 'תל אביב',
            id: '1',
            hashId: 'hash1',
            areaId: 1,
            areaName: 'תל אביב',
          ),
        ]);

        expect(provider.isLoadingAvailableLocations, isFalse);
        expect(provider.availableLocationsErrorMessage, isNull);
        expect(provider.availableLocations, hasLength(1));
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

class ThrowingDistrictsService extends OrefDistrictsService {
  ThrowingDistrictsService()
    : super(
        HttpClient(client: MockClient((_) async => http.Response('', 500))),
      );

  @override
  Future<List<OrefLocation>> fetchDistricts() async {
    throw Exception('catalog unavailable');
  }
}
