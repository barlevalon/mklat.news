import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_alerts_service.dart';

@GenerateMocks([HttpClient])
import 'oref_alerts_service_test.mocks.dart';

void main() {
  group('OrefAlertsService', () {
    late MockHttpClient mockHttpClient;
    late OrefAlertsService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = OrefAlertsService(mockHttpClient);
    });

    test('empty response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '');

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('whitespace-only response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '   \n\t  ');

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('BOM + whitespace response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '\uFEFF   ');

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test(
      'valid alert response returns correct list of Alert objects',
      () async {
        final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים",
          "desc": "היכנסו למרחב המוגן",
          "data": ["תל אביב - מרכז העיר"]
        }
      ''';

        when(
          mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
        ).thenAnswer((_) async => responseJson);

        final result = await service.fetchCurrentAlerts();

        expect(result.length, 1);
        expect(result.first.location, 'תל אביב - מרכז העיר');
        expect(result.first.title, 'ירי רקטות וטילים');
        expect(result.first.category, 1);
        expect(result.first.desc, 'היכנסו למרחב המוגן');
      },
    );

    test('multiple locations in data[] produce multiple Alerts', () async {
      final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים",
          "data": ["תל אביב - מרכז העיר", "חיפה - מערב", "ירושלים - מרכז"]
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result.length, 3);
      expect(result[0].location, 'תל אביב - מרכז העיר');
      expect(result[1].location, 'חיפה - מערב');
      expect(result[2].location, 'ירושלים - מרכז');
      // All should have same alert metadata
      for (final alert in result) {
        expect(alert.title, 'ירי רקטות וטילים');
        expect(alert.category, 1);
      }
    });

    test('invalid JSON returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => 'not valid json');

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('HTTP error rethrows HttpException', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenThrow(HttpException('HTTP 500', statusCode: 500));

      expect(() => service.fetchCurrentAlerts(), throwsA(isA<HttpException>()));
    });

    test('response with data as empty array returns empty list', () async {
      final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים",
          "data": []
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('response without data field returns empty list', () async {
      final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים"
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('response with non-array data returns empty list', () async {
      final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים",
          "data": "not an array"
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('response with non-object root returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '[1, 2, 3]');

      final result = await service.fetchCurrentAlerts();

      expect(result, isEmpty);
    });

    test('UAV category (2) is mapped correctly', () async {
      final responseJson = '''
        {
          "id": "133721700000000001",
          "cat": 2,
          "title": "חדירת כלי טיס עוין",
          "data": ["Location"]
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result.length, 1);
      expect(result.first.category, 2);
      expect(result.first.type, AlertCategory.uav);
    });

    test('clearance category (13) is mapped correctly', () async {
      final responseJson = '''
        {
          "id": "133721700000000002",
          "cat": 13,
          "title": "האירוע הסתיים",
          "data": ["Location"]
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result.length, 1);
      expect(result.first.category, 13);
      expect(result.first.type, AlertCategory.clearance);
    });

    test('alert IDs are unique per location', () async {
      final responseJson = '''
        {
          "id": "133721700000000000",
          "cat": 1,
          "title": "ירי רקטות וטילים",
          "data": ["Location A", "Location B"]
        }
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchCurrentAlerts();

      expect(result.length, 2);
      expect(result[0].id, isNot(equals(result[1].id)));
    });
  });
}
