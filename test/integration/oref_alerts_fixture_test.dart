import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/core/api_endpoints.dart';
import 'package:mklat/data/services/http_client.dart';
import 'package:mklat/data/services/oref_alerts_service.dart';
import 'package:mklat/domain/alert_state.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import '../fixtures/fixture_helper.dart';

import 'oref_alerts_fixture_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('OREF Alerts Fixture Tests', () {
    late MockClient mockClient;
    late HttpClient httpClient;
    late OrefAlertsService alertsService;

    setUp(() {
      mockClient = MockClient();
      httpClient = HttpClient(client: mockClient);
      alertsService = OrefAlertsService(httpClient);
    });

    tearDown(() {
      httpClient.dispose();
    });

    group('Empty alerts (BOM + CRLF)', () {
      test('returns empty list when no active alerts', () async {
        final fixture = await FixtureHelper.loadResponse('oref_alerts');

        when(
          mockClient.get(
            argThat(
              predicate<Uri>((uri) => uri.toString().contains('Alerts.json')),
            ),
            headers: anyNamed('headers'),
          ),
        ).thenAnswer((_) async => fixture);

        final alerts = await alertsService.fetchCurrentAlerts();

        expect(alerts, isEmpty);
      });

      test('BOM is properly stripped from raw bytes', () async {
        final fixture = await FixtureHelper.loadResponse('oref_alerts');

        when(
          mockClient.get(any, headers: anyNamed('headers')),
        ).thenAnswer((_) async => fixture);

        final result = await httpClient.get(
          ApiEndpoints.orefAlerts,
          useOrefHeaders: true,
        );

        // Verify BOM is stripped - result should not start with U+FEFF
        expect(result.startsWith('\uFEFF'), isFalse);
        // The body is just BOM + CRLF, so after stripping BOM and trimming, it's empty
        expect(result.trim().isEmpty, isTrue);
      });
    });

    group('Non-empty active alerts raw-byte pipeline', () {
      test(
        'parses Hebrew active alert bytes and drives red-alert state',
        () async {
          final bodyBytes = utf8.encode('''
          \uFEFF{
            "id": "133721700000000000",
            "cat": 1,
            "title": "ירי רקטות וטילים",
            "desc": "היכנסו למרחב המוגן",
            "data": ["תל אביב - מרכז העיר", "חיפה - מערב"]
          }
        ''');
          final fixture = http.Response.bytes(
            bodyBytes,
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );

          when(
            mockClient.get(
              argThat(
                predicate<Uri>((uri) => uri.toString().contains('Alerts.json')),
              ),
              headers: anyNamed('headers'),
            ),
          ).thenAnswer((_) async => fixture);

          final alerts = await alertsService.fetchCurrentAlerts();

          expect(alerts, hasLength(2));
          expect(alerts.first.location, 'תל אביב - מרכז העיר');
          expect(alerts.first.title, 'ירי רקטות וטילים');
          expect(alerts.first.desc, 'היכנסו למרחב המוגן');
          expect(alerts.first.category, 1);
          expect(alerts.first.location, isNot(contains('×')));

          final provider = AlertsProvider()
            ..setPrimaryLocation('תל אביב - מרכז העיר')
            ..onAlertData(alerts, []);
          addTearDown(provider.dispose);

          expect(provider.alertState, AlertState.redAlert);
          expect(
            provider.isLocationInActiveAlerts('תל אביב - מרכז העיר'),
            isTrue,
          );
          expect(provider.isLocationInActiveAlerts('ירושלים'), isFalse);
        },
      );
    });
  });
}
