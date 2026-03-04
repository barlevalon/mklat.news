import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_history_service.dart';
import '../fixtures/fixture_helper.dart';

import 'oref_history_fixture_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OREF History Fixture Tests', () {
    late MockClient mockClient;
    late HttpClient httpClient;
    late OrefHistoryService historyService;

    setUp(() {
      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
      historyService = OrefHistoryService(httpClient);
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('Real history fixture parsing', () {
      test('returns non-empty list from real fixture', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);
      });

      test('alerts have Hebrew title field', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);

        // Check first alert has Hebrew in title
        final firstAlert = alerts.first;
        final hasHebrew = RegExp(r'[\u0590-\u05FF]').hasMatch(firstAlert.title);
        expect(
          hasHebrew,
          isTrue,
          reason: 'Title should contain Hebrew: ${firstAlert.title}',
        );

        // Verify no mojibake
        expect(
          firstAlert.title.contains('×'),
          isFalse,
          reason: 'Title should not contain mojibake: ${firstAlert.title}',
        );
      });

      test('alerts have Hebrew location field', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);

        // Check first alert has Hebrew in location
        final firstAlert = alerts.first;
        final hasHebrew = RegExp(
          r'[\u0590-\u05FF]',
        ).hasMatch(firstAlert.location);
        expect(
          hasHebrew,
          isTrue,
          reason: 'Location should contain Hebrew: ${firstAlert.location}',
        );

        // Verify no mojibake
        expect(
          firstAlert.location.contains('×'),
          isFalse,
          reason:
              'Location should not contain mojibake: ${firstAlert.location}',
        );
      });

      test('time is parsed correctly from alertDate field', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);

        // Verify time is a valid DateTime (not epoch)
        final firstAlert = alerts.first;
        expect(firstAlert.time.year, greaterThanOrEqualTo(2025));
        expect(firstAlert.time.month, greaterThanOrEqualTo(1));
        expect(firstAlert.time.day, greaterThanOrEqualTo(1));
      });

      test('category is a valid integer', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);

        for (final alert in alerts) {
          expect(alert.category, isA<int>());
          expect(alert.category, greaterThanOrEqualTo(0));
        }
      });

      test('contains known Hebrew strings from fixture', () async {
        final fixture = await FixtureHelper.loadResponse('oref_history');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final alerts = await historyService.fetchAlertHistory();

        expect(alerts, isNotEmpty);

        // Collect all titles and locations
        final allText = alerts.map((a) => '${a.title} ${a.location}').join(' ');

        // Look for common Hebrew words that should appear in alerts
        // The fixture contains "האירוע הסתיים" (event ended) and location names
        final hasEventEnded =
            allText.contains('האירוע הסתיים') || allText.contains('הסתיים');
        final hasUav = allText.contains('כלי טיס') || allText.contains('עוין');

        // At least one of these patterns should be present
        expect(
          hasEventEnded || hasUav,
          isTrue,
          reason: 'Expected Hebrew alert text not found in: $allText',
        );
      });
    });

    group('Encoding verification', () {
      test('raw fixture bytes contain UTF-8 Hebrew', () async {
        final bodyBytes = await FixtureHelper.loadBodyBytes('oref_history');
        final decoded = utf8.decode(bodyBytes);

        // Verify the raw fixture has Hebrew
        expect(RegExp(r'[\u0590-\u05FF]').hasMatch(decoded), isTrue);

        // Verify no mojibake in raw decode
        expect(decoded.contains('×'), isFalse);
      });

      test('fixture has no charset in Content-Type', () async {
        final headers = await FixtureHelper.loadHeaders('oref_history');
        final contentType = headers['content-type'] ?? '';

        // The real API doesn't include charset
        expect(contentType.contains('charset'), isFalse);
      });
    });
  });
}
