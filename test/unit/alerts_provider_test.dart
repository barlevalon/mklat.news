import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/domain/alert_state.dart';

void main() {
  group('AlertsProvider', () {
    late AlertsProvider provider;

    setUp(() {
      provider = AlertsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state: loading, no alerts', () {
      expect(provider.isLoading, isTrue);
      expect(provider.currentAlerts, isEmpty);
      expect(provider.alertHistory, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.alertState, AlertState.allClear);
    });

    test('onAlertData: updates current/history, clears loading', () {
      final currentAlerts = [
        Alert(
          id: '1',
          location: 'תל אביב',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
      ];
      final historyAlerts = [
        Alert(
          id: '2',
          location: 'ירושלים',
          title: 'האירוע הסתיים',
          time: DateTime.now(),
          category: 13,
        ),
      ];

      provider.onAlertData(currentAlerts, historyAlerts);

      expect(provider.isLoading, isFalse);
      expect(provider.currentAlerts.length, 1);
      expect(provider.alertHistory.length, 1);
      expect(provider.errorMessage, isNull);
      expect(provider.lastUpdated, isNotNull);
    });

    test('onAlertData: runs state machine evaluation', () {
      provider.setPrimaryLocation('תל אביב');

      final currentAlerts = [
        Alert(
          id: '1',
          location: 'תל אביב',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
      ];

      provider.onAlertData(currentAlerts, []);

      expect(provider.alertState, AlertState.redAlert);
      expect(provider.alertStartTime, isNotNull);
    });

    test('setPrimaryLocation: delegates to state machine, notifies', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setPrimaryLocation('תל אביב');

      expect(notified, isTrue);
    });

    test('nationwideAlertCount: correct count', () {
      final currentAlerts = [
        Alert(
          id: '1',
          location: 'תל אביב',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
        Alert(
          id: '2',
          location: 'ירושלים',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
        Alert(
          id: '3',
          location: 'תל אביב',
          title: 'חדירת כלי טיס עוין',
          time: DateTime.now(),
          category: 2,
        ),
      ];

      provider.onAlertData(currentAlerts, []);

      expect(provider.nationwideAlertCount, 2); // תל אביב and ירושלים
    });

    test(
      'userLocationAlertCount: filters saved locations against active alerts',
      () {
        final currentAlerts = [
          Alert(
            id: '1',
            location: 'תל אביב',
            title: 'ירי רקטות וטילים',
            time: DateTime.now(),
            category: 1,
          ),
          Alert(
            id: '2',
            location: 'ירושלים',
            title: 'ירי רקטות וטילים',
            time: DateTime.now(),
            category: 1,
          ),
        ];

        provider.onAlertData(currentAlerts, []);

        final savedLocations = ['תל אביב', 'חיפה', 'באר שבע'];
        expect(provider.userLocationAlertCount(savedLocations), 1);
      },
    );

    test('alertsForLocation: filters history by location', () {
      final historyAlerts = [
        Alert(
          id: '1',
          location: 'תל אביב',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
        Alert(
          id: '2',
          location: 'ירושלים',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
        Alert(
          id: '3',
          location: 'תל אביב',
          title: 'האירוע הסתיים',
          time: DateTime.now(),
          category: 13,
        ),
      ];

      provider.onAlertData([], historyAlerts);

      final telAvivAlerts = provider.alertsForLocation('תל אביב');
      expect(telAvivAlerts.length, 2);
    });

    test('isLocationInActiveAlerts: correct matching', () {
      final currentAlerts = [
        Alert(
          id: '1',
          location: 'תל אביב',
          title: 'ירי רקטות וטילים',
          time: DateTime.now(),
          category: 1,
        ),
      ];

      provider.onAlertData(currentAlerts, []);

      expect(provider.isLocationInActiveAlerts('תל אביב'), isTrue);
      expect(provider.isLocationInActiveAlerts('ירושלים'), isFalse);
    });

    test('onError: sets error message', () {
      provider.onError('alerts', Exception('Network error'));

      expect(provider.errorMessage, 'שגיאה בטעינת התרעות');
    });
  });
}
