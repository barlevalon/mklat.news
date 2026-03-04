import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertsProvider Resume State', () {
    late AlertsProvider provider;

    setUp(() {
      provider = AlertsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('setResuming sets isResuming flag', () {
      // Initially false
      expect(provider.isResuming, isFalse);

      // Set to true
      provider.setResuming(true);
      expect(provider.isResuming, isTrue);

      // Set to false
      provider.setResuming(false);
      expect(provider.isResuming, isFalse);
    });

    test('setResuming notifies listeners', () {
      var notified = false;
      provider.addListener(() => notified = true);

      provider.setResuming(true);

      expect(notified, isTrue);
    });

    test('onAlertData clears isResuming flag', () {
      // Set resuming to true
      provider.setResuming(true);
      expect(provider.isResuming, isTrue);

      // Simulate data arriving
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

      // isResuming should be cleared
      expect(provider.isResuming, isFalse);
    });

    test('onError does not clear isResuming flag', () {
      // Set resuming to true
      provider.setResuming(true);
      expect(provider.isResuming, isTrue);

      // Simulate an error
      provider.onError('alerts', Exception('Network error'));

      // isResuming should still be true (overlay stays visible)
      expect(provider.isResuming, isTrue);
      // Error message should be set
      expect(provider.errorMessage, 'שגיאה בטעינת התרעות');
    });

    test('onAlertData clears isResuming even when error was set', () {
      // Set up error state
      provider.onError('alerts', Exception('Network error'));
      expect(provider.errorMessage, isNotNull);

      // Set resuming to true (app resumed while in error state)
      provider.setResuming(true);
      expect(provider.isResuming, isTrue);

      // Simulate data arriving (successful recovery)
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

      // Both isResuming and error should be cleared
      expect(provider.isResuming, isFalse);
      expect(provider.errorMessage, isNull);
    });

    test('isResuming defaults to false on new provider', () {
      final newProvider = AlertsProvider();
      expect(newProvider.isResuming, isFalse);
      newProvider.dispose();
    });
  });
}
