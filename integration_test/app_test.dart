import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mklat/main.dart';
import 'package:mklat/presentation/widgets/page_indicator.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test.mocks.dart';
import 'test_fixtures.dart';

@GenerateMocks([http.Client])
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('mklat integration tests', () {
    late MockClient mockClient;

    setUp(() {
      mockClient = MockClient();

      // Configure mock to return fixtures based on URL patterns
      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.path.contains('Alerts.json'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.oref_alerts);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('AlertsHistory.json')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.oref_history);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('GetDistricts.aspx')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.oref_districts);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('cities_heb.json')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.oref_cities);

      // RSS feeds
      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('ynet'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rss_ynet);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('maariv'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rss_maariv);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('walla'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rss_walla);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('haaretz'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rss_haaretz);
    });

    tearDown(() {
      mockClient.close();
    });

    testWidgets('app launches with empty state', (tester) async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));

      // Wait for initial load (don't use pumpAndSettle due to polling timers)
      await tester.pump(const Duration(seconds: 2));

      // Verify empty state UI
      expect(find.text('בחר אזור'), findsOneWidget);
      expect(find.text('הוסף מיקום כדי לראות התרעות'), findsOneWidget);

      // Verify page indicator dots (2 pages)
      expect(find.byType(PageIndicator), findsOneWidget);
    });

    testWidgets('add location flow', (tester) async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Tap location selector to open management modal
      await tester.tap(find.text('בחר אזור'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal opened with "המיקומים שלי" header
      expect(find.text('המיקומים שלי'), findsOneWidget);

      // Tap add button (Icons.add)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "הוסף מיקום" screen appears
      expect(find.text('הוסף מיקום'), findsOneWidget);

      // Wait for districts to load
      await tester.pump(const Duration(seconds: 1));

      // Type "שדה בועז" in search field — a mid-list city (index 763/1526)
      await tester.enterText(
        find.widgetWithText(TextField, 'חיפוש...'),
        'שדה בועז',
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Find the list item for "שדה בועז" (not the search field text)
      // The search field has our typed text, and the list should show the match
      final listItems = find.descendant(
        of: find.byType(ListView),
        matching: find.text('שדה בועז'),
      );
      expect(listItems, findsOneWidget);

      // Tap "שדה בועז" in the list to select it
      await tester.tap(listItems);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify checkmark appears
      expect(find.byIcon(Icons.check), findsOneWidget);

      // Check the "הגדר כמיקום ראשי" checkbox
      await tester.tap(find.text('הגדר כמיקום ראשי'));
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "שמור" button
      await tester.tap(find.text('שמור'));
      await tester.pump(const Duration(seconds: 1));

      // Verify we're back on status screen and location appears
      expect(find.text('שדה בועז'), findsOneWidget);

      // Verify status shows "אין התרעות" (all clear, no active alerts)
      expect(find.text('אין התרעות'), findsOneWidget);
    });

    testWidgets('swipe to news screen', (tester) async {
      // Clear SharedPreferences
      SharedPreferences.setMockInitialValues({});

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Swipe to news screen (page 1).
      // In RTL layout, PageView reverses scroll direction:
      // dragging left-to-right (positive offset) goes to the next page.
      await tester.dragFrom(
        tester.getCenter(find.byType(PageView)),
        const Offset(300, 0),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "מבזקי חדשות" header is visible
      expect(find.text('מבזקי חדשות'), findsOneWidget);

      // Wait for news to load
      await tester.pump(const Duration(seconds: 2));

      // Verify news items appear (at least one item with Hebrew text)
      // The fixture should have news items
      final hebrewPattern = RegExp(r'[\u0590-\u05FF]');
      final allTexts = find.byType(Text);
      bool foundHebrew = false;
      for (var i = 0; i < allTexts.evaluate().length; i++) {
        final element = allTexts.evaluate().elementAt(i);
        final text = element.widget is Text
            ? (element.widget as Text).data ?? ''
            : '';
        if (hebrewPattern.hasMatch(text)) {
          foundHebrew = true;
          break;
        }
      }
      expect(
        foundHebrew,
        isTrue,
        reason: 'Expected to find Hebrew text in news items',
      );
    });

    testWidgets('status screen shows all clear with location', (tester) async {
      // Pre-populate SharedPreferences with a saved location
      // Key must match AppConstants.savedLocationsKey ('mklat_saved_locations')
      // JSON must match SavedLocation.fromJson format (no createdAt field)
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations':
            '[{"id":"test-id","orefName":"שדה בועז","customLabel":"","isPrimary":true,"shelterTimeSec":90}]',
      });

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Verify location name appears in selector
      expect(find.text('שדה בועז'), findsOneWidget);

      // Verify "אין התרעות" is displayed (no active alerts in fixture)
      expect(find.text('אין התרעות'), findsOneWidget);
    });
  });
}
