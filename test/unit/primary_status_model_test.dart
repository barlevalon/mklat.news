import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/domain/alert_state.dart';
import 'package:mklat/presentation/models/primary_status_model.dart';

void main() {
  group('PrimaryStatusModel', () {
    test('offline state overrides alert state and hides instruction/timer', () {
      final model = PrimaryStatusModel.build(
        isOffline: true,
        alertErrorMessage: null,
        alertState: AlertState.redAlert,
        alertStartTime: DateTime(2026, 3, 4, 14, 30),
      );

      expect(model.visual, PrimaryStatusVisual.offline);
      expect(model.icon, '📡');
      expect(model.title, 'אין חיבור');
      expect(model.instruction, null);
      expect(model.showInstruction, false);
      expect(model.showElapsedTimer, false);
    });

    test('error state shows unknown status and no timer', () {
      final model = PrimaryStatusModel.build(
        isOffline: false,
        alertErrorMessage: 'שגיאה בטעינת התרעות',
        alertState: AlertState.redAlert,
        alertStartTime: DateTime(2026, 3, 4, 14, 30),
      );

      expect(model.visual, PrimaryStatusVisual.error);
      expect(model.icon, '⚠️');
      expect(model.title, 'מצב לא ידוע');
      expect(model.instruction, 'לא ניתן לאמת התרעות כרגע');
      expect(model.showInstruction, true);
      expect(model.showElapsedTimer, false);
    });

    test('normal state uses alert-state presentation values', () {
      final startTime = DateTime(2026, 3, 4, 14, 30);

      final model = PrimaryStatusModel.build(
        isOffline: false,
        alertErrorMessage: null,
        alertState: AlertState.redAlert,
        alertStartTime: startTime,
      );

      expect(model.visual, PrimaryStatusVisual.normal);
      expect(model.alertState, AlertState.redAlert);
      expect(model.icon, AlertState.redAlert.icon);
      expect(model.title, 'צבע אדום');
      expect(model.instruction, 'היכנסו למרחב המוגן');
      expect(model.elapsedStartTime, startTime);
      expect(model.showElapsedTimer, true);
    });

    test('normal non-timer state omits elapsed timer', () {
      final model = PrimaryStatusModel.build(
        isOffline: false,
        alertErrorMessage: null,
        alertState: AlertState.allClear,
        alertStartTime: DateTime(2026, 3, 4, 14, 30),
      );

      expect(model.title, 'אין התרעות');
      expect(model.showInstruction, false);
      expect(model.showElapsedTimer, false);
    });
  });
}
