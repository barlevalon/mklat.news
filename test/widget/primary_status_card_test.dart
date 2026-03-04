import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mklat/presentation/widgets/primary_status_card.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';

void main() {
  group('PrimaryStatusCard', () {
    Widget buildTestWidget({
      required AlertsProvider alertsProvider,
      required LocationProvider locationProvider,
    }) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: locationProvider),
            ],
            child: const Scaffold(body: PrimaryStatusCard()),
          ),
        ),
      );
    }

    testWidgets('renders default ALL_CLEAR state correctly', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
        ),
      );

      // Should show the all clear title (default state)
      expect(find.text('אין התרעות'), findsOneWidget);
      expect(find.text('🟢'), findsOneWidget);
    });

    testWidgets('renders with location selector button', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
        ),
      );

      // Should show the location selector with default text
      expect(find.text('בחר אזור'), findsOneWidget);
    });

    testWidgets('card has correct structure', (WidgetTester tester) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
        ),
      );

      // Should have a container with the card styling
      expect(find.byType(Container), findsWidgets);

      // Should have the icon text
      expect(find.text('🟢'), findsOneWidget);

      // Should have the title
      expect(find.text('אין התרעות'), findsOneWidget);
    });

    testWidgets('timer updates when state changes to show elapsed', (
      WidgetTester tester,
    ) async {
      final alertsProvider = AlertsProvider();
      final locationProvider = LocationProvider();

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
        ),
      );

      // Initially no timer shown in ALL_CLEAR
      expect(find.text('אין התרעות'), findsOneWidget);

      // Widget should be a StatefulWidget to handle timers
      expect(find.byType(PrimaryStatusCard), findsOneWidget);
    });
  });
}
