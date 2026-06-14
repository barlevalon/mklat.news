import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/presentation/widgets/primary_status_card.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() {
  group('PrimaryStatusCard', () {
    Widget buildTestWidget({
      required AlertsProvider alertsProvider,
      required LocationProvider locationProvider,
      required ConnectivityProvider connectivityProvider,
      DateTime Function()? now,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: locationProvider),
              ChangeNotifierProvider.value(value: connectivityProvider),
            ],
            child: Scaffold(body: PrimaryStatusCard(now: now ?? DateTime.now)),
          ),
        ),
      );
    }

    testWidgets('renders default ALL_CLEAR state correctly', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );

      // Should show the all clear title (default state)
      expect(find.text('אין התרעות'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('renders with location selector button', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );

      // Should show the location selector with default text
      expect(find.text('בחר אזור'), findsOneWidget);
    });

    testWidgets('card has correct structure', (WidgetTester tester) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );

      // Should have a container with the card styling
      expect(find.byType(Container), findsWidgets);

      // Should have the cohesive Material status icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Should have the title
      expect(find.text('אין התרעות'), findsOneWidget);
    });

    testWidgets('timer updates while red alert is visible', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      final startTime = DateTime(2026, 1, 1, 12);
      final clock = FakeClock(startTime);
      alertsProvider.setPrimaryLocation('רחובות');
      final activeAlert = Alert(
        id: 'active_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: startTime,
        category: 1,
      );
      alertsProvider.onAlertData([activeAlert], [activeAlert]);

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
          now: clock.now,
        ),
      );

      expect(find.text('00:00'), findsOneWidget);
      expect(find.byType(ElapsedTimeText), findsOneWidget);

      clock.advance(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('00:02'), findsOneWidget);
    });

    testWidgets('does not mount elapsed timer outside active states', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );

      expect(find.text('אין התרעות'), findsOneWidget);
      expect(find.byType(ElapsedTimeText), findsNothing);
    });

    group('offline state', () {
      testWidgets('shows grey background and "אין חיבור" when offline', (
        WidgetTester tester,
      ) async {
        final controller = StreamController<ConnectivityResult>();
        final alertsProvider = AlertsProvider();
        final locationProvider = LocationProvider();
        final connectivityProvider = ConnectivityProvider.fromStream(
          controller.stream,
        );

        // Start online
        controller.add(ConnectivityResult.wifi);
        await connectivityProvider.initialize();

        await tester.pumpWidget(
          buildTestWidget(
            alertsProvider: alertsProvider,
            locationProvider: locationProvider,
            connectivityProvider: connectivityProvider,
          ),
        );
        await tester.pump();

        // Initially online - should show all clear
        expect(find.text('אין התרעות'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        // Go offline
        controller.add(ConnectivityResult.none);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show offline state
        expect(find.text('אין חיבור'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

        // Should NOT show instruction text when offline
        expect(find.text('היכנסו למרחב המוגן'), findsNothing);

        await controller.close();
      });

      testWidgets('does not show timer when offline', (
        WidgetTester tester,
      ) async {
        final controller = StreamController<ConnectivityResult>();
        final alertsProvider = AlertsProvider();
        final locationProvider = LocationProvider();
        final connectivityProvider = ConnectivityProvider.fromStream(
          controller.stream,
        );

        // Start offline
        controller.add(ConnectivityResult.none);
        await connectivityProvider.initialize();

        await tester.pumpWidget(
          buildTestWidget(
            alertsProvider: alertsProvider,
            locationProvider: locationProvider,
            connectivityProvider: connectivityProvider,
          ),
        );
        await tester.pump();

        // Should show offline state
        expect(find.text('אין חיבור'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);

        // Wait a bit to ensure no timer appears
        await tester.pump(const Duration(seconds: 2));

        // Should still show offline state, no timer
        expect(find.text('אין חיבור'), findsOneWidget);
        expect(find.byType(ElapsedTimeText), findsNothing);

        await controller.close();
      });

      testWidgets('returns to online state when connectivity restored', (
        WidgetTester tester,
      ) async {
        final controller = StreamController<ConnectivityResult>();
        final alertsProvider = AlertsProvider();
        final locationProvider = LocationProvider();
        final connectivityProvider = ConnectivityProvider.fromStream(
          controller.stream,
        );

        // Start offline
        controller.add(ConnectivityResult.none);
        await connectivityProvider.initialize();

        await tester.pumpWidget(
          buildTestWidget(
            alertsProvider: alertsProvider,
            locationProvider: locationProvider,
            connectivityProvider: connectivityProvider,
          ),
        );
        await tester.pump();

        // Should show offline state
        expect(find.text('אין חיבור'), findsOneWidget);

        // Go back online
        controller.add(ConnectivityResult.wifi);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show all clear again
        expect(find.text('אין התרעות'), findsOneWidget);
        expect(find.byIcon(Icons.check_rounded), findsOneWidget);

        await controller.close();
      });
    });

    testWidgets('justCleared state does not show redundant timestamp', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      // Drive state machine to JUST_CLEARED
      alertsProvider.setPrimaryLocation('רחובות');

      final activeAlert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now(),
        category: 1,
      );
      alertsProvider.onAlertData([activeAlert], []);
      alertsProvider.onAlertData([], []);

      final clearanceAlert = Alert(
        id: 'test_2',
        location: 'רחובות',
        title: 'האירוע הסתיים',
        time: DateTime.now(),
        category: 13,
      );
      alertsProvider.onAlertData([], [clearanceAlert]);

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump();

      // Should show "האירוע הסתיים" title
      expect(find.text('האירוע הסתיים'), findsOneWidget);
      // Should show clearance instruction
      expect(find.text('ניתן לצאת מהמרחב המוגן'), findsOneWidget);
      // Should NOT show any "דקות" timestamp (this is the bug - currently it does)
      expect(find.textContaining('דקות'), findsNothing);
      // Should NOT show "עכשיו" either
      expect(find.textContaining('עכשיו'), findsNothing);
    });

    testWidgets('renders with dark-appropriate background in dark mode', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();
      final connectivityProvider = ConnectivityProvider.fromStream(
        Stream.value(ConnectivityResult.wifi),
      );
      await connectivityProvider.initialize();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: alertsProvider),
                ChangeNotifierProvider.value(value: locationProvider),
                ChangeNotifierProvider.value(value: connectivityProvider),
              ],
              child: const Scaffold(body: PrimaryStatusCard()),
            ),
          ),
        ),
      );

      // Find the card container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      final decoratedContainers = containerFinder.evaluate().map((element) {
        return (element.widget as Container).decoration;
      }).whereType<BoxDecoration>();

      expect(
        decoratedContainers.any(
          (decoration) => decoration.color == const Color(0xFF162029),
        ),
        isTrue,
        reason: 'card shell should use a dark civic surface in dark mode',
      );
    });
  });
}

class FakeClock {
  DateTime _now;

  FakeClock(this._now);

  DateTime now() => _now;

  void advance(Duration duration) {
    _now = _now.add(duration);
  }
}
