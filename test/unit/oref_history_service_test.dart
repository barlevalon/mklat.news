import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_history_service.dart';

@GenerateMocks([HttpClient])
import 'oref_history_service_test.mocks.dart';

void main() {
  group('OrefHistoryService', () {
    late MockHttpClient mockHttpClient;
    late OrefHistoryService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = OrefHistoryService(mockHttpClient);
    });

    test('valid history response returns correct list of Alerts', () async {
      final responseJson = '''
        [
          {
            "alertDate": "2026-03-04 14:09:32",
            "title": "ירי רקטות וטילים",
            "data": "גבעת הראל",
            "category": 1
          },
          {
            "alertDate": "2026-03-04 14:08:15",
            "title": "חדירת כלי טיס עוין",
            "data": "תל אביב - מרכז",
            "category": 2
          }
        ]
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchAlertHistory();

      expect(result.length, 2);
      expect(result[0].location, 'גבעת הראל');
      expect(result[0].title, 'ירי רקטות וטילים');
      expect(result[0].category, 1);
      expect(result[0].time.year, 2026);
      expect(result[0].time.month, 3);
      expect(result[0].time.day, 4);
      expect(result[0].time.hour, 14);
      expect(result[0].time.minute, 9);
      expect(result[0].time.second, 32);

      expect(result[1].location, 'תל אביב - מרכז');
      expect(result[1].category, 2);
    });

    test('empty response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '');

      final result = await service.fetchAlertHistory();

      expect(result, isEmpty);
    });

    test('whitespace-only response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '   \n\t  ');

      final result = await service.fetchAlertHistory();

      expect(result, isEmpty);
    });

    test('invalid JSON returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => 'not valid json');

      final result = await service.fetchAlertHistory();

      expect(result, isEmpty);
    });

    test('HTTP error rethrows HttpException', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenThrow(HttpException('HTTP 500', statusCode: 500));

      expect(() => service.fetchAlertHistory(), throwsA(isA<HttpException>()));
    });

    test('entries with different categories are mapped correctly', () async {
      final responseJson = '''
        [
          {"alertDate": "2026-03-04 14:00:00", "title": "ירי רקטות", "data": "A", "category": 1},
          {"alertDate": "2026-03-04 14:01:00", "title": "כלי טיס עוין", "data": "B", "category": 2},
          {"alertDate": "2026-03-04 14:02:00", "title": "האירוע הסתיים", "data": "C", "category": 13},
          {"alertDate": "2026-03-04 14:03:00", "title": "התרעה צפויה", "data": "D", "category": 14},
          {"alertDate": "2026-03-04 14:04:00", "title": "רעידת אדמה", "data": "E", "category": 99}
        ]
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchAlertHistory();

      expect(result.length, 5);
      expect(result[0].type, AlertCategory.rockets);
      expect(result[1].type, AlertCategory.uav);
      expect(result[2].type, AlertCategory.clearance);
      expect(result[3].type, AlertCategory.imminent);
      expect(result[4].type, AlertCategory.other);
    });

    test('non-array response returns empty list', () async {
      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => '{"not": "an array"}');

      final result = await service.fetchAlertHistory();

      expect(result, isEmpty);
    });

    test('desc is null for all history entries', () async {
      final responseJson = '''
        [
          {
            "alertDate": "2026-03-04 14:09:32",
            "title": "ירי רקטות וטילים",
            "data": "Location",
            "category": 1
          }
        ]
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchAlertHistory();

      expect(result.length, 1);
      expect(result.first.desc, null);
    });

    test('ID is synthesized from alertDate and data', () async {
      final responseJson = '''
        [
          {
            "alertDate": "2026-03-04 14:09:32",
            "title": "ירי רקטות וטילים",
            "data": "גבעת הראל",
            "category": 1
          }
        ]
      ''';

      when(
        mockHttpClient.get(any, useOrefHeaders: anyNamed('useOrefHeaders')),
      ).thenAnswer((_) async => responseJson);

      final result = await service.fetchAlertHistory();

      expect(result.first.id, '2026-03-04 14:09:32_גבעת הראל');
    });
  });
}
