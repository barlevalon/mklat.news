import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/presentation/widgets/nationwide_summary.dart';
import 'package:mklat/presentation/providers/alerts_provider.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/data/models/alert.dart';
import 'package:mklat/data/models/saved_location.dart';

void main() {
  group('NationwideSummary', () {
    Widget buildTestWidget({
      required AlertsProvider alertsProvider,
      required LocationProvider locationProvider,
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: alertsProvider),
              ChangeNotifierProvider.value(value: locationProvider),
            ],
            child: const Scaffold(body: NationwideSummary()),
          ),
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('does not use hardcoded light orange background in dark mode', (
      WidgetTester tester,
    ) async {
      // Set up alerts provider with an active alert
      final alertsProvider = AlertsProvider();
      final activeAlert = Alert(
        id: 'test_alert_1',
        location: 'תל אביב',
        title: 'ירי רקטות וטילים',
        time: DateTime.now(),
        category: 1,
      );
      alertsProvider.onAlertData([activeAlert], []);

      // Set up location provider with a saved location
      final locationProvider = LocationProvider();
      final savedLocation = SavedLocation(
        id: 'loc_1',
        orefName: 'רחובות',
        customLabel: 'בית',
        isPrimary: true,
      );
      // Use test helper to set locations directly
      locationProvider.loadAvailableLocationsForTest([]);
      // Add location via the public API (we need at least one location)
      await locationProvider.addLocation(savedLocation);

      await tester.pumpWidget(
        buildTestWidget(
          alertsProvider: alertsProvider,
          locationProvider: locationProvider,
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();

      // Verify the summary is rendered (nationwide count > 0)
      expect(find.byType(NationwideSummary), findsOneWidget);
      expect(find.textContaining('באזורים שלך'), findsOneWidget);

      // Find the container with the orange background
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Get the first Container that has a BoxDecoration (the summary card)
      final container = tester.widget<Container>(containerFinder.first);
      final decoration = container.decoration as BoxDecoration?;

      // The current code uses Colors.orange.shade50 which is 0xFFFFF3E0
      // In dark mode, this light orange background is inappropriate
      expect(
        decoration?.color,
        isNot(equals(Colors.orange.shade50)),
        reason:
            'NationwideSummary should not use hardcoded light orange (Colors.orange.shade50) in dark mode',
      );
    });
  });
}
