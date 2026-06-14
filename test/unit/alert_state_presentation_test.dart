import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/domain/alert_state.dart';
import 'package:mklat/presentation/models/alert_state_presentation.dart';

void main() {
  group('AlertStatePresentation', () {
    test('maps titles', () {
      expect(
        AlertStatePresentation.fromState(AlertState.allClear).title,
        'אין התרעות',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.alertImminent).title,
        'התרעה צפויה',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.redAlert).title,
        'צבע אדום',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.waitingClear).title,
        'המתינו במרחב המוגן',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.justCleared).title,
        'האירוע הסתיים',
      );
    });

    test('maps instructions', () {
      expect(
        AlertStatePresentation.fromState(AlertState.allClear).instruction,
        null,
      );
      expect(
        AlertStatePresentation.fromState(AlertState.alertImminent).instruction,
        'התרעות צפויות בדקות הקרובות',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.redAlert).instruction,
        'היכנסו למרחב המוגן',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.waitingClear).instruction,
        'ממתינים לאישור יציאה',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.justCleared).instruction,
        'ניתן לצאת מהמרחב המוגן',
      );
    });

    test('maps icons', () {
      expect(AlertStatePresentation.fromState(AlertState.allClear).icon, '🟢');
      expect(
        AlertStatePresentation.fromState(AlertState.alertImminent).icon,
        '⚠️',
      );
      expect(AlertStatePresentation.fromState(AlertState.redAlert).icon, '🚨');
      expect(
        AlertStatePresentation.fromState(AlertState.waitingClear).icon,
        '◷',
      );
      expect(
        AlertStatePresentation.fromState(AlertState.justCleared).icon,
        '✅',
      );
    });
  });
}
