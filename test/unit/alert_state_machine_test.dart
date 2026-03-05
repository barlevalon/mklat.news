import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/domain/alert_state.dart';
import 'package:mklat/domain/alert_state_machine.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertStateMachine - Basic transitions', () {
    test('1. Initial state is ALL_CLEAR', () {
      final machine = AlertStateMachine();

      expect(machine.currentState, AlertState.allClear);
      expect(machine.alertStartTime, isNull);
      expect(machine.clearanceTime, isNull);
      expect(machine.primaryLocation, isNull);
    });

    test('2. ALL_CLEAR → RED_ALERT when primary location in active alerts', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז', 'חיפה'},
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
      expect(result.alertStartTime, isNotNull);
    });

    test('3. ALL_CLEAR → ALERT_IMMINENT when cat 14 in history', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );

      expect(result.state, AlertState.alertImminent);
    });

    test(
      '4. ALERT_IMMINENT → RED_ALERT when primary location in active alerts',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // First, enter ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );
        expect(machine.currentState, AlertState.alertImminent);

        // Now active alert arrives
        final result = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
        );

        expect(result.state, AlertState.redAlert);
      },
    );

    test(
      '5. ALERT_IMMINENT → JUST_CLEARED when cat 13 in history (threat resolved without red alert)',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // First, enter ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );
        expect(machine.currentState, AlertState.alertImminent);

        // Now cat 13 arrives (threat resolved)
        final result = machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
            Alert(
              id: '2',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: DateTime.now(),
              category: 13,
            ),
          ],
        );

        expect(result.state, AlertState.justCleared);
        expect(result.clearanceTime, isNotNull);
      },
    );

    test(
      '6. RED_ALERT → WAITING_CLEAR when location drops from active, no cat 13',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // Enter RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
        );
        expect(machine.currentState, AlertState.redAlert);

        // Alert drops, no cat 13
        final result = machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [],
        );

        expect(result.state, AlertState.waitingClear);
      },
    );

    test('7. WAITING_CLEAR → JUST_CLEARED when cat 13 in history', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );

      // Enter WAITING_CLEAR
      machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
      expect(machine.currentState, AlertState.waitingClear);

      // Cat 13 arrives
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: DateTime.now(),
            category: 13,
          ),
        ],
      );

      expect(result.state, AlertState.justCleared);
      expect(result.clearanceTime, isNotNull);
    });

    test(
      '8. WAITING_CLEAR → RED_ALERT when location reappears in active (re-entry)',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // Enter RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
        );

        // Enter WAITING_CLEAR
        machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
        expect(machine.currentState, AlertState.waitingClear);

        // Re-enter RED_ALERT
        final result = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
        );

        expect(result.state, AlertState.redAlert);
      },
    );

    test('9. JUST_CLEARED → ALL_CLEAR after 10 minutes', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR (alert drops, no cat 13)
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      // Enter JUST_CLEARED (cat 13 arrives)
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );
      expect(machine.currentState, AlertState.justCleared);

      // Still JUST_CLEARED at 9 minutes after clearance (11 minutes total)
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 11)),
      );
      expect(machine.currentState, AlertState.justCleared);

      // ALL_CLEAR at 12 minutes (10 minutes after clearanceTime at minute 2)
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 12)),
      );
      expect(result.state, AlertState.allClear);
    });

    test('10. JUST_CLEARED → RED_ALERT on new attack during cooldown', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      // Enter JUST_CLEARED
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );
      expect(machine.currentState, AlertState.justCleared);

      // New attack during cooldown (5 minutes later)
      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 7)),
      );

      expect(result.state, AlertState.redAlert);
    });
  });

  group('AlertStateMachine - Full paths', () {
    test(
      '11. Full path: ALL_CLEAR → ALERT_IMMINENT → RED_ALERT → WAITING_CLEAR → JUST_CLEARED → ALL_CLEAR',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');
        final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

        // Start: ALL_CLEAR
        expect(machine.currentState, AlertState.allClear);

        // Cat 14 arrives → ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: baseTime,
              category: 14,
            ),
          ],
          now: baseTime,
        );
        expect(machine.currentState, AlertState.alertImminent);

        // Active alert arrives → RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
          now: baseTime.add(Duration(minutes: 1)),
        );
        expect(machine.currentState, AlertState.redAlert);

        // Alert drops → WAITING_CLEAR
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [],
          now: baseTime.add(Duration(minutes: 2)),
        );
        expect(machine.currentState, AlertState.waitingClear);

        // Cat 13 arrives → JUST_CLEARED
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '2',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 2)),
              category: 13,
            ),
          ],
          now: baseTime.add(Duration(minutes: 3)),
        );
        expect(machine.currentState, AlertState.justCleared);

        // 10 minutes pass → ALL_CLEAR
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '2',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 2)),
              category: 13,
            ),
          ],
          now: baseTime.add(Duration(minutes: 13)),
        );
        expect(machine.currentState, AlertState.allClear);
      },
    );

    test('12. Direct path: ALL_CLEAR → RED_ALERT (no prior imminent)', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Direct to RED_ALERT without cat 14
      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
    });

    test('13. Short path: ALERT_IMMINENT → JUST_CLEARED (threat resolved)', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter ALERT_IMMINENT
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );
      expect(machine.currentState, AlertState.alertImminent);

      // Threat resolved without ever going to RED_ALERT
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
          Alert(
            id: '2',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: DateTime.now(),
            category: 13,
          ),
        ],
      );

      expect(result.state, AlertState.justCleared);
    });

    test(
      'ALERT_IMMINENT → WAITING_CLEAR when attack materializes in history (cat 1/2) but not caught in active alerts',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('רחובות');
        final baseTime = DateTime(2026, 3, 5, 13, 42, 0);

        // Cat 14 arrives → ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'רחובות',
              title: 'בדקות הקרובות צפויות להתקבל התרעות באזורך',
              time: baseTime,
              category: 14,
            ),
          ],
          now: baseTime,
        );
        expect(machine.currentState, AlertState.alertImminent);

        // Cat 1 (rockets) appears in history — attack materialized
        // but was never caught in active alerts (polling missed it)
        // No cat 13 clearance yet
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'רחובות',
              title: 'בדקות הקרובות צפויות להתקבל התרעות באזורך',
              time: baseTime,
              category: 14,
            ),
            Alert(
              id: '2',
              location: 'רחובות',
              title: 'ירי רקטות וטילים',
              time: baseTime.add(Duration(minutes: 5)),
              category: 1,
            ),
          ],
          now: baseTime.add(Duration(minutes: 6)),
        );

        // Should have escalated to WAITING_CLEAR because the attack
        // actually happened (cat 1 in history proves it)
        expect(machine.currentState, AlertState.waitingClear);
      },
    );

    test(
      'stale cat 13 from previous attack does not trigger JUST_CLEARED for new attack',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('אשדוד');
        final baseTime = DateTime(2026, 3, 5, 22, 30, 0);

        // === First attack cycle ===
        // RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'אשדוד'},
          historyForPrimary: [],
          now: baseTime,
        );
        expect(machine.currentState, AlertState.redAlert);

        // Active drops → WAITING_CLEAR
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: 'attack1',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime,
              category: 1,
            ),
          ],
          now: baseTime.add(Duration(minutes: 2)),
        );
        expect(machine.currentState, AlertState.waitingClear);

        // Cat 13 clearance for first attack → JUST_CLEARED
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: 'attack1',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime,
              category: 1,
            ),
            Alert(
              id: 'clear1',
              location: 'אשדוד',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 5)),
              category: 13,
            ),
          ],
          now: baseTime.add(Duration(minutes: 5)),
        );
        expect(machine.currentState, AlertState.justCleared);

        // 10 minutes pass → ALL_CLEAR
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: 'attack1',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime,
              category: 1,
            ),
            Alert(
              id: 'clear1',
              location: 'אשדוד',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 5)),
              category: 13,
            ),
          ],
          now: baseTime.add(Duration(minutes: 16)),
        );
        expect(machine.currentState, AlertState.allClear);

        // === Second attack cycle (20 minutes later) ===
        // New RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'אשדוד'},
          historyForPrimary: [
            // History still contains the old cat 13 from first attack
            Alert(
              id: 'attack1',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime,
              category: 1,
            ),
            Alert(
              id: 'clear1',
              location: 'אשדוד',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 5)),
              category: 13,
            ),
            Alert(
              id: 'attack2',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime.add(Duration(minutes: 20)),
              category: 1,
            ),
          ],
          now: baseTime.add(Duration(minutes: 20)),
        );
        expect(machine.currentState, AlertState.redAlert);

        // Active drops, no new clearance yet → should be WAITING_CLEAR
        // BUG: the stale cat 13 from 15 minutes ago (first attack) is still
        // in history, causing the machine to jump to JUST_CLEARED
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: 'attack1',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime,
              category: 1,
            ),
            Alert(
              id: 'clear1',
              location: 'אשדוד',
              title: 'האירוע הסתיים',
              time: baseTime.add(Duration(minutes: 5)),
              category: 13,
            ),
            Alert(
              id: 'attack2',
              location: 'אשדוד',
              title: 'ירי רקטות וטילים',
              time: baseTime.add(Duration(minutes: 20)),
              category: 1,
            ),
          ],
          now: baseTime.add(Duration(minutes: 22)),
        );

        // Should be WAITING_CLEAR (no NEW clearance for the second attack)
        // BUG: currently goes to JUST_CLEARED because of stale cat 13
        expect(machine.currentState, AlertState.waitingClear);
      },
    );
  });

  group('AlertStateMachine - Priority rules', () {
    test(
      '15. Active alert ALWAYS wins → RED_ALERT regardless of current state',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // From ALL_CLEAR with cat 14
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );
        expect(machine.currentState, AlertState.redAlert);

        // From WAITING_CLEAR with cat 13
        machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
        expect(machine.currentState, AlertState.waitingClear);

        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: DateTime.now(),
              category: 13,
            ),
          ],
        );
        expect(machine.currentState, AlertState.redAlert);

        // From JUST_CLEARED (need to go through full cycle)
        // First go to WAITING_CLEAR (no active, no cat 13)
        machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
        expect(machine.currentState, AlertState.waitingClear);

        // Then to JUST_CLEARED (cat 13 arrives)
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: DateTime.now(),
              category: 13,
            ),
          ],
        );
        expect(machine.currentState, AlertState.justCleared);

        // Active alert during JUST_CLEARED → RED_ALERT
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: DateTime.now(),
              category: 13,
            ),
          ],
        );
        expect(machine.currentState, AlertState.redAlert);
      },
    );

    test(
      '16. RED_ALERT self-loop: alertStartTime NOT reset when staying in RED_ALERT',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');
        final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

        // Enter RED_ALERT
        final result1 = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
          now: baseTime,
        );
        final firstAlertTime = result1.alertStartTime;
        expect(firstAlertTime, isNotNull);

        // Stay in RED_ALERT (self-loop)
        final result2 = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
          now: baseTime.add(Duration(seconds: 5)),
        );

        expect(result2.state, AlertState.redAlert);
        expect(result2.alertStartTime, firstAlertTime); // Same time, not reset
      },
    );

    test('17. RED_ALERT → RED_ALERT preserves alertStartTime', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );
      final firstAlertTime = machine.alertStartTime;

      // Multiple evaluations while still active
      for (int i = 1; i <= 5; i++) {
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
          now: baseTime.add(Duration(seconds: i * 2)),
        );
        expect(machine.alertStartTime, firstAlertTime);
      }
    });
  });

  group('AlertStateMachine - WAITING_CLEAR specifics', () {
    test('18. WAITING_CLEAR has NO auto-timeout (stays indefinitely)', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );
      expect(machine.currentState, AlertState.waitingClear);

      // Stay in WAITING_CLEAR for a long time (30 minutes)
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 31)),
      );
      expect(machine.currentState, AlertState.waitingClear);

      // Even longer (2 hours)
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(hours: 2)),
      );
      expect(machine.currentState, AlertState.waitingClear);
    });

    test('19. WAITING_CLEAR entered ONLY from RED_ALERT', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // From ALL_CLEAR with no active alert - stays ALL_CLEAR
      machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
      expect(machine.currentState, AlertState.allClear);

      // From ALERT_IMMINENT with no active alert - stays ALERT_IMMINENT
      machine.setPrimaryLocation('חיפה'); // Reset
      machine.setPrimaryLocation('תל אביב - מרכז');
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );
      expect(machine.currentState, AlertState.alertImminent);

      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );
      expect(machine.currentState, AlertState.alertImminent);

      // Only from RED_ALERT does it go to WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );
      expect(machine.currentState, AlertState.redAlert);

      machine.evaluate(activeAlertLocations: {}, historyForPrimary: []);
      expect(machine.currentState, AlertState.waitingClear);
    });

    test(
      '20. NOT entered from ALERT_IMMINENT when alert drops without cat 13',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // Enter ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );
        expect(machine.currentState, AlertState.alertImminent);

        // No active alert, no cat 13 - stays ALERT_IMMINENT
        machine.evaluate(
          activeAlertLocations: {},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );
        expect(machine.currentState, AlertState.alertImminent);
      },
    );
  });

  group('AlertStateMachine - Location management', () {
    test('21. setPrimaryLocation resets to ALL_CLEAR from any state', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );
      expect(machine.currentState, AlertState.redAlert);

      // Change location - should reset
      machine.setPrimaryLocation('חיפה');
      expect(machine.currentState, AlertState.allClear);
      expect(machine.alertStartTime, isNull);
      expect(machine.clearanceTime, isNull);
    });

    test('22. setPrimaryLocation(same value) does NOT reset state', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );
      expect(machine.currentState, AlertState.redAlert);
      final alertTime = machine.alertStartTime;

      // Set same location - should NOT reset
      machine.setPrimaryLocation('תל אביב - מרכז');
      expect(machine.currentState, AlertState.redAlert);
      expect(machine.alertStartTime, alertTime);
    });

    test('23. setPrimaryLocation(null) → ALL_CLEAR', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );
      expect(machine.currentState, AlertState.redAlert);

      // Set null - should reset
      machine.setPrimaryLocation(null);
      expect(machine.currentState, AlertState.allClear);
      expect(machine.primaryLocation, isNull);
    });

    test(
      '24. null primary location → always ALL_CLEAR regardless of inputs',
      () {
        final machine = AlertStateMachine();
        // No primary location set

        final result = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'התרעה צפויה',
              time: DateTime.now(),
              category: 14,
            ),
          ],
        );

        expect(result.state, AlertState.allClear);
      },
    );
  });

  group('AlertStateMachine - Location matching', () {
    test('25. Exact match works', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
    });

    test('26. Whitespace normalization works', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל   אביב   -   מרכז'); // Extra spaces

      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'}, // Normal spaces
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
    });

    test('27. Hebrew quote normalization works (״ → ")', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('יישוב ״הגנה״'); // Hebrew gershayim

      final result = machine.evaluate(
        activeAlertLocations: {'יישוב "הגנה"'}, // Regular quotes
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
    });

    test('28. Double-single-quote normalization works (\'\' → ")', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation("יישוב ''הגנה''"); // Double single quotes

      final result = machine.evaluate(
        activeAlertLocations: {'יישוב "הגנה"'}, // Regular quotes
        historyForPrimary: [],
      );

      expect(result.state, AlertState.redAlert);
    });

    test('29. No match returns false', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      final result = machine.evaluate(
        activeAlertLocations: {'חיפה', 'ירושלים'},
        historyForPrimary: [],
      );

      expect(result.state, AlertState.allClear);
    });
  });

  group('AlertStateMachine - Timer tracking', () {
    test('30. alertStartTime set when entering RED_ALERT', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      expect(machine.alertStartTime, isNull);

      final result = machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      expect(result.state, AlertState.redAlert);
      expect(result.alertStartTime, baseTime);
    });

    test('31. alertStartTime preserved during RED_ALERT self-loop', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );
      final firstTime = machine.alertStartTime;

      // Multiple self-loops
      for (int i = 1; i <= 3; i++) {
        machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [],
          now: baseTime.add(Duration(seconds: i)),
        );
        expect(machine.alertStartTime, firstTime);
      }
    });

    test('32. alertStartTime cleared when returning to ALL_CLEAR', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );
      expect(machine.alertStartTime, isNotNull);

      // Go through full cycle to ALL_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );

      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 12)),
      );

      expect(machine.currentState, AlertState.allClear);
      expect(machine.alertStartTime, isNull);
    });

    test('33. clearanceTime set when entering JUST_CLEARED', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      expect(machine.clearanceTime, isNull);

      // Enter JUST_CLEARED
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );

      expect(result.state, AlertState.justCleared);
      expect(result.clearanceTime, baseTime.add(Duration(minutes: 2)));
    });

    test('34. clearanceTime cleared when returning to ALL_CLEAR', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      // Enter JUST_CLEARED
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );
      expect(machine.clearanceTime, isNotNull);

      // Return to ALL_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 12)),
      );

      expect(machine.currentState, AlertState.allClear);
      expect(machine.clearanceTime, isNull);
    });

    test('35. JUST_CLEARED → ALL_CLEAR at exactly 10 minutes', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');
      final baseTime = DateTime(2026, 3, 4, 14, 0, 0);

      // Enter RED_ALERT
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
        now: baseTime,
      );

      // Enter WAITING_CLEAR
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
        now: baseTime.add(Duration(minutes: 1)),
      );

      // Enter JUST_CLEARED at minute 2
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 2)),
      );

      // At exactly 12 minutes (10 minutes after clearance), should be ALL_CLEAR
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: baseTime,
            category: 13,
          ),
        ],
        now: baseTime.add(Duration(minutes: 12)),
      );

      expect(result.state, AlertState.allClear);
    });
  });

  group('AlertStateMachine - Edge cases', () {
    test('36. Empty active alerts + empty history → stay in current state', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Start in ALL_CLEAR
      expect(machine.currentState, AlertState.allClear);

      // Empty inputs - stays ALL_CLEAR
      var result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
      );
      expect(result.state, AlertState.allClear);

      // Enter ALERT_IMMINENT
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );
      expect(machine.currentState, AlertState.alertImminent);

      // Empty inputs - stays ALERT_IMMINENT
      result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [],
      );
      expect(result.state, AlertState.alertImminent);
    });

    test('37. Both cat 13 and cat 14 in history → cat 13 takes priority', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // First enter ALERT_IMMINENT
      machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
        ],
      );
      expect(machine.currentState, AlertState.alertImminent);

      // Both cat 13 and cat 14 present - cat 13 should win (JUST_CLEARED)
      final result = machine.evaluate(
        activeAlertLocations: {},
        historyForPrimary: [
          Alert(
            id: '1',
            location: 'תל אביב - מרכז',
            title: 'התרעה צפויה',
            time: DateTime.now(),
            category: 14,
          ),
          Alert(
            id: '2',
            location: 'תל אביב - מרכז',
            title: 'האירוע הסתיים',
            time: DateTime.now(),
            category: 13,
          ),
        ],
      );

      expect(result.state, AlertState.justCleared);
    });

    test(
      '38. Active alert AND cat 13 in history → RED_ALERT wins (evaluation order rule 1)',
      () {
        final machine = AlertStateMachine();
        machine.setPrimaryLocation('תל אביב - מרכז');

        // Both active alert and cat 13 present - active alert wins
        final result = machine.evaluate(
          activeAlertLocations: {'תל אביב - מרכז'},
          historyForPrimary: [
            Alert(
              id: '1',
              location: 'תל אביב - מרכז',
              title: 'האירוע הסתיים',
              time: DateTime.now(),
              category: 13,
            ),
          ],
        );

        expect(result.state, AlertState.redAlert);
      },
    );

    test('39. reset() returns to initial state', () {
      final machine = AlertStateMachine();
      machine.setPrimaryLocation('תל אביב - מרכז');

      // Enter various states
      machine.evaluate(
        activeAlertLocations: {'תל אביב - מרכז'},
        historyForPrimary: [],
      );
      expect(machine.currentState, AlertState.redAlert);

      // Reset
      machine.reset();

      expect(machine.currentState, AlertState.allClear);
      expect(machine.alertStartTime, isNull);
      expect(machine.clearanceTime, isNull);
      expect(machine.primaryLocation, isNull);
    });
  });

  group('AlertStateMachine - Public static locationsMatch', () {
    test('locationsMatch returns true for matching locations', () {
      expect(
        AlertStateMachine.locationsMatch('תל אביב - מרכז', 'תל אביב - מרכז'),
        isTrue,
      );
      expect(AlertStateMachine.locationsMatch('תל   אביב', 'תל אביב'), isTrue);
      expect(
        AlertStateMachine.locationsMatch('יישוב ״הגנה״', 'יישוב "הגנה"'),
        isTrue,
      );
    });

    test('locationsMatch returns false for non-matching locations', () {
      expect(AlertStateMachine.locationsMatch('תל אביב', 'חיפה'), isFalse);
      expect(
        AlertStateMachine.locationsMatch('תל אביב - מרכז', 'תל אביב - צפון'),
        isFalse,
      );
    });
  });
}
