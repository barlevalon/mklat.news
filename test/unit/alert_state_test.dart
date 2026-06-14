import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/domain/alert_state.dart';

void main() {
  group('AlertState', () {
    test('showElapsedTimer is true for redAlert and waitingClear', () {
      expect(AlertState.allClear.showElapsedTimer, false);
      expect(AlertState.alertImminent.showElapsedTimer, false);
      expect(AlertState.redAlert.showElapsedTimer, true);
      expect(AlertState.waitingClear.showElapsedTimer, true);
      expect(AlertState.justCleared.showElapsedTimer, false);
    });

    test('isElevated is false only for allClear', () {
      expect(AlertState.allClear.isElevated, false);
      expect(AlertState.alertImminent.isElevated, true);
      expect(AlertState.redAlert.isElevated, true);
      expect(AlertState.waitingClear.isElevated, true);
      expect(AlertState.justCleared.isElevated, true);
    });

    test('isDanger is true for redAlert and waitingClear', () {
      expect(AlertState.allClear.isDanger, false);
      expect(AlertState.alertImminent.isDanger, false);
      expect(AlertState.redAlert.isDanger, true);
      expect(AlertState.waitingClear.isDanger, true);
      expect(AlertState.justCleared.isDanger, false);
    });
  });
}
