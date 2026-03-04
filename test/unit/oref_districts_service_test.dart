import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/core/app_constants.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_districts_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([HttpClient])
import 'oref_districts_service_test.mocks.dart';

void main() {
  group('OrefDistrictsService', () {
    late MockHttpClient mockHttpClient;
    late OrefDistrictsService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = OrefDistrictsService(mockHttpClient);
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'valid Districts response returns correct list of OrefLocation',
      () async {
        final districtsJson = '''
        [
          {
            "label_he": "אבו גוש",
            "value": "6657AD46BF8FA430B022FF282B7A804B",
            "id": "511",
            "areaid": 5,
            "areaname": "בית שמש",
            "migun_time": 90
          },
          {
            "label_he": "תל אביב - מרכז",
            "value": "ABC123",
            "id": "123",
            "areaid": 1,
            "areaname": "תל אביב",
            "migun_time": 60
          }
        ]
      ''';

        when(
          mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
        ).thenAnswer((_) async => districtsJson);

        final result = await service.fetchDistricts();

        expect(result.length, 2);
        expect(result[0].name, 'אבו גוש');
        expect(result[0].id, '511');
        expect(result[0].hashId, '6657AD46BF8FA430B022FF282B7A804B');
        expect(result[0].areaId, 5);
        expect(result[0].areaName, 'בית שמש');
        expect(result[0].shelterTimeSec, 90);

        expect(result[1].name, 'תל אביב - מרכז');
        expect(result[1].shelterTimeSec, 60);
      },
    );

    test('fallback to cities_heb.json when Districts fails', () async {
      final citiesJson = '''
        [
          {
            "label": "אבו גוש | אזור שפלת יהודה",
            "cityAlId": "6657AD46BF8FA430B022FF282B7A804B",
            "id": "511",
            "areaid": 5
          }
        ]
      ''';

      // First call (Districts) fails
      when(
        mockHttpClient.get(
          argThat(
            predicate<String>((url) => url.contains('GetDistricts.aspx')),
          ),
          useOrefHeaders: anyNamed('useOrefHeaders'),
        ),
      ).thenThrow(HttpException('HTTP 500', statusCode: 500));

      // Second call (cities fallback) succeeds
      when(
        mockHttpClient.get(
          argThat(predicate<String>((url) => url.contains('cities_heb.json'))),
          useOrefHeaders: anyNamed('useOrefHeaders'),
        ),
      ).thenAnswer((_) async => citiesJson);

      final result = await service.fetchDistricts();

      expect(result.length, 1);
      expect(result[0].name, 'אבו גוש');
      expect(result[0].areaName, 'אזור שפלת יהודה');
      expect(result[0].shelterTimeSec, null); // Fallback has no shelter time
    });

    test('cache hit returns cached data without API call', () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        AppConstants.districtsCacheKey:
            '[{"name":"Cached Location","id":"999","hashId":"cached-hash","areaId":1,"areaName":"Cached Area","shelterTimeSec":45}]',
        AppConstants.districtsCacheTimestampKey: now.toIso8601String(),
      });

      final result = await service.fetchDistricts();

      expect(result.length, 1);
      expect(result[0].name, 'Cached Location');
      expect(result[0].shelterTimeSec, 45);

      // Verify no API calls were made
      verifyNever(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      );
    });

    test('cache miss (expired) triggers fresh fetch', () async {
      final expiredTime = DateTime.now().subtract(const Duration(hours: 25));
      final districtsJson =
          '[{"label_he":"Fresh Location","value":"fresh123","id":"1","areaid":1,"areaname":"Area","migun_time":30}]';

      SharedPreferences.setMockInitialValues({
        AppConstants.districtsCacheKey:
            '[{"name":"Old Location","id":"999","hashId":"old-hash","areaId":1,"areaName":"Old Area","shelterTimeSec":60}]',
        AppConstants.districtsCacheTimestampKey: expiredTime.toIso8601String(),
      });

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => districtsJson);

      final result = await service.fetchDistricts();

      expect(result.length, 1);
      expect(result[0].name, 'Fresh Location');
      expect(result[0].shelterTimeSec, 30);
    });

    test('both endpoints fail returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenThrow(HttpException('HTTP 500', statusCode: 500));

      final result = await service.fetchDistricts();

      expect(result, isEmpty);
    });

    test('successful fetch caches the data', () async {
      final districtsJson =
          '[{"label_he":"Test Location","value":"test123","id":"1","areaid":1,"areaname":"Area","migun_time":45}]';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => districtsJson);

      await service.fetchDistricts();

      // Second call should use cache
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(AppConstants.districtsCacheKey);
      expect(cached, isNotNull);
      expect(cached, contains('Test Location'));
    });

    test('empty Districts response falls back to cities', () async {
      final citiesJson =
          '[{"label":"Test | Area","cityAlId":"V1","id":"1","areaid":1}]';

      when(
        mockHttpClient.get(
          argThat(
            predicate<String>((url) => url.contains('GetDistricts.aspx')),
          ),
          useOrefHeaders: anyNamed('useOrefHeaders'),
        ),
      ).thenAnswer((_) async => '[]');

      when(
        mockHttpClient.get(
          argThat(predicate<String>((url) => url.contains('cities_heb.json'))),
          useOrefHeaders: anyNamed('useOrefHeaders'),
        ),
      ).thenAnswer((_) async => citiesJson);

      final result = await service.fetchDistricts();

      expect(result.length, 1);
    });

    test('invalid JSON from both endpoints returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => 'invalid json');

      final result = await service.fetchDistricts();

      expect(result, isEmpty);
    });

    test('cache stores locations in internal JSON format', () async {
      final districtsJson =
          '[{"label_he":"Test","value":"v","id":"1","areaid":1,"areaname":"Area","migun_time":30}]';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => districtsJson);

      await service.fetchDistricts();

      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(AppConstants.districtsCacheKey);
      expect(cached, isNotNull);
      // Should be in internal format (name, id, hashId, etc.) not API format
      expect(cached, contains('"name"'));
      expect(cached, contains('"hashId"'));
      expect(cached, contains('"areaId"'));
    });
  });
}
