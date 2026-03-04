import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_districts_service.dart';
import '../fixtures/fixture_helper.dart';

import 'oref_districts_fixture_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OREF Districts Fixture Tests', () {
    late MockClient mockClient;
    late HttpClient httpClient;
    late OrefDistrictsService districtsService;

    setUp(() {
      // Clear SharedPreferences cache before each test
      SharedPreferences.setMockInitialValues({});

      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
      districtsService = OrefDistrictsService(httpClient);
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('Districts (primary source)', () {
      test('returns 1000+ locations from districts fixture', () async {
        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();

        expect(locations.length, greaterThan(1000));
      });

      test('Hebrew names are intact in districts', () async {
        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();

        // Look for known Hebrew city names
        final allNames = locations.map((l) => l.name).join(' ');

        // Check for major cities (at least one should be present)
        final hasTelAviv = allNames.contains('תל אביב');
        final hasJerusalem = allNames.contains('ירושלים');
        final hasHaifa = allNames.contains('חיפה');
        final hasEilat = allNames.contains('אילת');

        expect(
          hasTelAviv || hasJerusalem || hasHaifa || hasEilat,
          isTrue,
          reason: 'Expected major city not found',
        );

        // Verify no mojibake in any name
        for (final location in locations) {
          expect(
            location.name.contains('×'),
            isFalse,
            reason: 'Mojibake in name: ${location.name}',
          );
        }
      });

      test('shelterTimeSec is populated on entries that have it', () async {
        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();

        // Some locations should have shelter times
        final withShelter = locations
            .where((l) => l.shelterTimeSec != null)
            .toList();
        expect(withShelter, isNotEmpty);

        // Verify shelter times are reasonable values
        for (final location in withShelter) {
          expect(location.shelterTimeSec, isA<int>());
          expect(location.shelterTimeSec, greaterThanOrEqualTo(0));
          expect(location.shelterTimeSec, lessThanOrEqualTo(180));
        }
      });

      test('areaName is populated with Hebrew', () async {
        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();

        // All locations should have areaName
        for (final location in locations) {
          expect(location.areaName, isNotEmpty);

          // Verify Hebrew in areaName
          final hasHebrew = RegExp(
            r'[\u0590-\u05FF]',
          ).hasMatch(location.areaName);
          expect(
            hasHebrew,
            isTrue,
            reason: 'areaName should have Hebrew: ${location.areaName}',
          );

          // No mojibake
          expect(location.areaName.contains('×'), isFalse);
        }
      });

      test('non-standard charset=UTF8 is handled', () async {
        final headers = await FixtureHelper.loadHeaders('oref_districts');
        final contentType = headers['content-type'] ?? '';

        // Verify the fixture has the non-standard charset
        expect(contentType.contains('UTF8'), isTrue);
        expect(contentType.contains('utf-8'), isFalse); // No dash!

        // The service should still work
        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();
        expect(locations, isNotEmpty);

        // Verify Hebrew is intact
        final firstLocation = locations.first;
        expect(RegExp(r'[\u0590-\u05FF]').hasMatch(firstLocation.name), isTrue);
      });
    });

    group('Cities fallback', () {
      test('returns 1350+ entries from cities fallback', () async {
        final citiesFixture = await FixtureHelper.loadResponse('oref_cities');

        // First call returns empty (simulating failure), second call uses fallback
        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response.bytes(utf8.encode('[]'), 200));

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('cities_heb.json'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => citiesFixture);

        final locations = await districtsService.fetchDistricts();

        expect(locations.length, greaterThan(1300));
      });

      test('Hebrew names parsed correctly from cities fallback', () async {
        final citiesFixture = await FixtureHelper.loadResponse('oref_cities');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response.bytes(utf8.encode('[]'), 200));

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('cities_heb.json'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => citiesFixture);

        final locations = await districtsService.fetchDistricts();

        // Verify Hebrew names
        final allNames = locations.map((l) => l.name).join(' ');
        expect(RegExp(r'[\u0590-\u05FF]').hasMatch(allNames), isTrue);

        // No mojibake
        for (final location in locations) {
          expect(
            location.name.contains('×'),
            isFalse,
            reason: 'Mojibake in name: ${location.name}',
          );
        }
      });

      test('pipe separator handled correctly', () async {
        final citiesFixture = await FixtureHelper.loadResponse('oref_cities');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response.bytes(utf8.encode('[]'), 200));

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('cities_heb.json'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => citiesFixture);

        final locations = await districtsService.fetchDistricts();

        // Find a location with pipe separator (e.g., "אבו גוש | אזור שפלת יהודה")
        final pipedLocations = locations
            .where((l) => l.areaName.isNotEmpty)
            .toList();
        expect(pipedLocations, isNotEmpty);

        // Verify the name doesn't include the pipe part
        for (final location in pipedLocations.take(10)) {
          expect(
            location.name.contains('|'),
            isFalse,
            reason: 'Name should not contain pipe: ${location.name}',
          );
        }
      });

      test('entries without pipe have empty areaName', () async {
        final citiesFixture = await FixtureHelper.loadResponse('oref_cities');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response.bytes(utf8.encode('[]'), 200));

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('cities_heb.json'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => citiesFixture);

        final locations = await districtsService.fetchDistricts();

        // Find locations without pipe (like "אזור תעשייה שחורת")
        final noPipeLocations = locations
            .where((l) => l.areaName.isEmpty)
            .toList();

        // Some should exist
        expect(noPipeLocations, isNotEmpty);

        // Verify their names are still valid
        for (final location in noPipeLocations.take(5)) {
          expect(location.name, isNotEmpty);
          expect(RegExp(r'[\u0590-\u05FF]').hasMatch(location.name), isTrue);
        }
      });

      test('cityAlId is used as hashId (not value)', () async {
        final citiesFixture = await FixtureHelper.loadResponse('oref_cities');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => http.Response.bytes(utf8.encode('[]'), 200));

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('cities_heb.json'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => citiesFixture);

        final locations = await districtsService.fetchDistricts();

        // Verify hashIds look like the cityAlId format (32 hex chars)
        for (final location in locations.take(10)) {
          expect(
            location.hashId.length,
            equals(32),
            reason: 'hashId should be 32 char hex: ${location.hashId}',
          );
          expect(
            RegExp(r'^[A-F0-9]{32}$').hasMatch(location.hashId),
            isTrue,
            reason: 'hashId should be uppercase hex: ${location.hashId}',
          );
        }
      });
    });

    group('Cache behavior', () {
      test('fetches from network when cache is empty', () async {
        // Ensure cache is empty via setUp

        final fixture = await FixtureHelper.loadResponse('oref_districts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>(
                (uri) => uri.toString().contains('GetDistricts.aspx'),
              ),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final locations = await districtsService.fetchDistricts();

        expect(locations, isNotEmpty);
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      });
    });
  });
}
