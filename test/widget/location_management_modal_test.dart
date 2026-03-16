import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/presentation/screens/location_management_modal.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/data/models/saved_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationManagementModal', () {
    Widget buildTestWidget(LocationProvider locationProvider) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider.value(
            value: locationProvider,
            child: const LocationManagementModal(),
          ),
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows empty state when no locations', (
      WidgetTester tester,
    ) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('אין מיקומים שמורים'), findsOneWidget);
      expect(find.text('הוסף מיקום ראשון'), findsOneWidget);
    });

    testWidgets('shows saved locations list', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      final location1 = SavedLocation.create(
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
      );
      final location2 = SavedLocation.create(
        orefName: 'הרצליה - מערב',
        customLabel: 'עבודה',
        isPrimary: false,
      );

      await provider.addLocation(location1);
      await provider.addLocation(location2);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('המיקומים שלי'), findsOneWidget);
      expect(find.text('בית'), findsOneWidget);
      expect(find.text('עבודה'), findsOneWidget);
      expect(find.text('תל אביב - מרכז'), findsOneWidget);
      expect(find.text('הרצליה - מערב'), findsOneWidget);
    });

    testWidgets('primary location has star icon', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      final location = SavedLocation.create(
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
      );
      await provider.addLocation(location);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('tap location calls setPrimary', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      final location1 = SavedLocation.create(
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
      );
      final location2 = SavedLocation.create(
        orefName: 'הרצליה - מערב',
        customLabel: 'עבודה',
        isPrimary: false,
      );

      await provider.addLocation(location1);
      await provider.addLocation(location2);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Tap on the second location (עבודה)
      await tester.tap(find.text('עבודה'));
      await tester.pumpAndSettle();

      // Modal should close and primary should be updated
      expect(provider.primaryLocation?.displayLabel, 'עבודה');
    });

    testWidgets('shows add button in header', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('shows add location button at bottom when locations exist', (
      WidgetTester tester,
    ) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      final location = SavedLocation.create(
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
      );
      await provider.addLocation(location);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('הוסף מיקום'), findsOneWidget);
    });

    testWidgets('empty state text uses theme color in dark mode', (
      WidgetTester tester,
    ) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: ChangeNotifierProvider.value(
              value: provider,
              child: const LocationManagementModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('אין מיקומים שמורים'));
      final textColor = textWidget.style?.color;

      // Should NOT be hardcoded Colors.grey in dark mode
      expect(textColor, isNot(equals(Colors.grey)));
    });
  });
}
