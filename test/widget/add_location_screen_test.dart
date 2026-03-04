import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mklat/presentation/screens/add_location_screen.dart';
import 'package:mklat/presentation/providers/location_provider.dart';
import 'package:mklat/data/models/oref_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AddLocationScreen', () {
    Widget buildTestWidget(LocationProvider locationProvider) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ChangeNotifierProvider.value(
            value: locationProvider,
            child: const AddLocationScreen(),
          ),
        ),
      );
    }

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('renders search field', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      // Set up available locations
      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('הוסף מיקום'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(2)); // Label + Search
      expect(find.text('חיפוש...'), findsOneWidget);
    });

    testWidgets('renders save button', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('שמור'), findsOneWidget);
    });

    testWidgets('search filters location list', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
        const OrefLocation(
          name: 'ירושלים - מרכז',
          id: '2',
          hashId: 'hash2',
          areaId: 2,
          areaName: 'ירושלים',
          shelterTimeSec: 90,
        ),
        const OrefLocation(
          name: 'חיפה - מרכז',
          id: '3',
          hashId: 'hash3',
          areaId: 3,
          areaName: 'חיפה',
          shelterTimeSec: 60,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // All locations should be visible initially
      expect(find.text('תל אביב - מרכז'), findsOneWidget);
      expect(find.text('ירושלים - מרכז'), findsOneWidget);
      expect(find.text('חיפה - מרכז'), findsOneWidget);

      // Enter search query
      await tester.enterText(find.byType(TextField).at(1), 'תל אביב');
      await tester.pumpAndSettle();

      // Only matching location should be visible
      expect(find.text('תל אביב - מרכז'), findsOneWidget);
      expect(find.text('ירושלים - מרכז'), findsNothing);
      expect(find.text('חיפה - מרכז'), findsNothing);
    });

    testWidgets('shows loading state when no available locations', (
      WidgetTester tester,
    ) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('טוען רשימת אזורים...'), findsOneWidget);
    });

    testWidgets('shows no results when search has no matches', (
      WidgetTester tester,
    ) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      // Enter search query with no matches
      await tester.enterText(find.byType(TextField).at(1), 'xyz');
      await tester.pumpAndSettle();

      expect(find.text('לא נמצאו תוצאות'), findsOneWidget);
    });

    testWidgets('renders custom label field', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('שם מותאם (לא חובה)'), findsOneWidget);
      expect(find.text('בית, עבודה...'), findsOneWidget);
    });

    testWidgets('renders set as primary checkbox', (WidgetTester tester) async {
      final provider = LocationProvider();
      await provider.loadLocations();

      provider.loadAvailableLocationsForTest([
        const OrefLocation(
          name: 'תל אביב - מרכז',
          id: '1',
          hashId: 'hash1',
          areaId: 1,
          areaName: 'תל אביב',
          shelterTimeSec: 90,
        ),
      ]);

      await tester.pumpWidget(buildTestWidget(provider));
      await tester.pumpAndSettle();

      expect(find.text('הגדר כמיקום ראשי'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });
}
