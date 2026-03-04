import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/domain/alert_state.dart';

void main() {
  group('AlertState', () {
    test('hebrewTitle returns correct Hebrew text', () {
      expect(AlertState.allClear.hebrewTitle, 'אין התרעות');
      expect(AlertState.alertImminent.hebrewTitle, 'התרעה צפויה');
      expect(AlertState.redAlert.hebrewTitle, 'צבע אדום');
      expect(AlertState.waitingClear.hebrewTitle, 'המתינו במרחב המוגן');
      expect(AlertState.justCleared.hebrewTitle, 'האירוע הסתיים');
    });

    test('instruction returns correct text', () {
      expect(AlertState.allClear.instruction, null);
      expect(
        AlertState.alertImminent.instruction,
        'התרעות צפויות בדקות הקרובות',
      );
      expect(AlertState.redAlert.instruction, 'היכנסו למרחב המוגן');
      expect(AlertState.waitingClear.instruction, 'ממתינים לאישור יציאה');
      expect(AlertState.justCleared.instruction, 'ניתן לצאת מהמרחב המוגן');
    });

    test('icon returns correct emoji', () {
      expect(AlertState.allClear.icon, '🟢');
      expect(AlertState.alertImminent.icon, '⚠️');
      expect(AlertState.redAlert.icon, '🚨');
      expect(AlertState.waitingClear.icon, '◷');
      expect(AlertState.justCleared.icon, '✅');
    });

    test('showElapsedTimer is true for redAlert and waitingClear', () {
      expect(AlertState.allClear.showElapsedTimer, false);
      expect(AlertState.alertImminent.showElapsedTimer, false);
      expect(AlertState.redAlert.showElapsedTimer, true);
      expect(AlertState.waitingClear.showElapsedTimer, true);
      expect(AlertState.justCleared.showElapsedTimer, false);
    });

    test('showTimeSince is true for justCleared only', () {
      expect(AlertState.allClear.showTimeSince, false);
      expect(AlertState.alertImminent.showTimeSince, false);
      expect(AlertState.redAlert.showTimeSince, false);
      expect(AlertState.waitingClear.showTimeSince, false);
      expect(AlertState.justCleared.showTimeSince, true);
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
