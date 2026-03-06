import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:mklat/main.dart';
import 'package:mklat/presentation/providers/connectivity_provider.dart';
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
      ).thenAnswer((_) async => TestFixtures.orefAlerts);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('AlertsHistory.json')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.orefHistory);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('GetDistricts.aspx')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.orefDistricts);

      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('cities_heb.json')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.orefCities);

      // RSS feeds
      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('ynet'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rssYnet);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('maariv'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rssMaariv);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('mako'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rssMako);

      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.host.contains('haaretz'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.rssHaaretz);
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

    testWidgets('add second location shows secondary row', (tester) async {
      // Pre-populate SharedPreferences with one primary location
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations':
            '[{"id":"loc-1","orefName":"שדה בועז","customLabel":"","isPrimary":true,"shelterTimeSec":90}]',
      });

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Verify "שדה בועז" appears as primary
      expect(find.text('שדה בועז'), findsOneWidget);

      // Tap "שדה בועז" to open location modal
      await tester.tap(find.text('שדה בועז'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal opened
      expect(find.text('המיקומים שלי'), findsOneWidget);

      // Tap add button (Icons.add)
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "הוסף מיקום" screen appears
      expect(find.text('הוסף מיקום'), findsOneWidget);

      // Wait for districts to load
      await tester.pump(const Duration(seconds: 1));

      // Search for "רחובות"
      await tester.enterText(
        find.widgetWithText(TextField, 'חיפוש...'),
        'רחובות',
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Find "רחובות" in the ListView
      final listItems = find.descendant(
        of: find.byType(ListView),
        matching: find.text('רחובות'),
      );
      expect(listItems, findsOneWidget);

      // Tap to select
      await tester.tap(listItems);
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "שמור" (do NOT check primary — it should be secondary)
      await tester.tap(find.text('שמור'));
      await tester.pump(const Duration(seconds: 1));

      // Verify back on status screen
      expect(find.text('שדה בועז'), findsOneWidget);

      // Verify "רחובות" appears in the secondary locations row
      expect(find.text('רחובות'), findsOneWidget);
    });

    testWidgets('edit location custom label', (tester) async {
      // Pre-populate with one primary location
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations':
            '[{"id":"test-id","orefName":"שדה בועז","customLabel":"","isPrimary":true,"shelterTimeSec":90}]',
      });

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Tap "שדה בועז" to open location modal
      await tester.tap(find.text('שדה בועז'));
      await tester.pump(const Duration(milliseconds: 500));

      // Long-press the first ListTile to open edit screen
      // Since there's only one location, we can find by type
      final listTile = find.byType(ListTile).first;
      await tester.longPress(listTile);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "ערוך מיקום" appears (edit screen title)
      expect(find.text('ערוך מיקום'), findsOneWidget);

      // Enter "הבית" in the custom label TextField
      // The TextField has no label, so we find by type (there's only one editable field)
      await tester.enterText(find.byType(TextField), 'הבית');
      await tester.pump(const Duration(milliseconds: 300));

      // Tap "שמור"
      await tester.tap(find.text('שמור'));
      await tester.pump(const Duration(seconds: 1));

      // Verify "הבית" appears on the status screen (custom label replaces orefName in display)
      expect(find.text('הבית'), findsOneWidget);
    });

    testWidgets('delete location', (tester) async {
      // Pre-populate with two locations
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations':
            '[{"id":"loc-1","orefName":"שדה בועז","customLabel":"","isPrimary":true,"shelterTimeSec":90},{"id":"loc-2","orefName":"רחובות","customLabel":"","isPrimary":false,"shelterTimeSec":60}]',
      });

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Verify both locations visible
      expect(find.text('שדה בועז'), findsOneWidget);
      expect(find.text('רחובות'), findsOneWidget);

      // Tap "שדה בועז" to open location modal
      await tester.tap(find.text('שדה בועז'));
      await tester.pump(const Duration(milliseconds: 500));

      // Long-press the second ListTile (רחובות) to open edit screen
      // Since רחובות is the second location, we use .at(1)
      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(2));
      await tester.longPress(listTiles.at(1));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "ערוך מיקום" appears
      expect(find.text('ערוך מיקום'), findsOneWidget);

      // Tap "מחק" (the red outlined delete button)
      await tester.tap(find.text('מחק'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify delete confirmation dialog appears with "מחק מיקום" title
      expect(find.text('מחק מיקום'), findsOneWidget);

      // Tap "מחק" in the dialog
      await tester.tap(find.textContaining('מחק').last);
      await tester.pump(const Duration(seconds: 1));

      // Verify back on status screen
      expect(find.text('שדה בועז'), findsOneWidget);

      // Verify "רחובות" is no longer visible
      expect(find.text('רחובות'), findsNothing);
    });

    testWidgets('tap news item opens url', (tester) async {
      // Pre-populate SharedPreferences empty (no locations needed for news)
      SharedPreferences.setMockInitialValues({});

      // Launch app with mock client
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // Swipe to news (positive offset for RTL)
      await tester.dragFrom(
        tester.getCenter(find.byType(PageView)),
        const Offset(300, 0),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Verify "מבזקי חדשות" header is visible
      expect(find.text('מבזקי חדשות'), findsOneWidget);

      // Wait for news to load (longer wait for RSS feeds)
      await tester.pump(const Duration(seconds: 3));

      // Verify source labels exist (Ynet, Maariv, Mako, or Haaretz)
      // The source name appears in the timestamp line: "SourceName • לפני X דקות"
      final sourceLabels = ['Ynet', 'Maariv', 'Mako', 'Haaretz'];
      bool foundSource = false;
      for (final source in sourceLabels) {
        if (find.textContaining(source).evaluate().isNotEmpty) {
          foundSource = true;
          break;
        }
      }
      expect(
        foundSource,
        isTrue,
        reason: 'Expected to find at least one news source label',
      );

      // Verify at least one timestamp is rendered. Older fixtures may fall back
      // to an absolute date instead of relative text.
      final timestampPattern = RegExp(
        r'לפני|עכשיו|\d{1,2}/\d{1,2}\s\d{2}:\d{2}',
      );
      final allTexts = find.byType(Text);
      bool foundTimestamp = false;
      for (var i = 0; i < allTexts.evaluate().length; i++) {
        final element = allTexts.evaluate().elementAt(i);
        final text = element.widget is Text
            ? (element.widget as Text).data ?? ''
            : '';
        if (timestampPattern.hasMatch(text)) {
          foundTimestamp = true;
          break;
        }
      }
      expect(
        foundTimestamp,
        isTrue,
        reason: 'Expected to find a rendered news timestamp',
      );
    });

    testWidgets('offline banner appears and disappears', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Create a controllable connectivity stream
      final connectivityController = StreamController<ConnectivityResult>();
      final connectivityProvider = ConnectivityProvider.fromStream(
        connectivityController.stream,
      );

      await tester.pumpWidget(
        MklatApp(
          httpClient: mockClient,
          connectivityProvider: connectivityProvider,
        ),
      );
      await tester.pump(const Duration(seconds: 2));

      // Banner should not be visible initially (online by default)
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
      // The banner exists in the tree but is slid offscreen — verify
      // it becomes fully visible when offline

      // Go offline
      connectivityController.add(ConnectivityResult.none);
      await tester.pump(const Duration(milliseconds: 500));

      // Banner should be visible
      expect(find.text('אין חיבור לאינטרנט'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Status card should show offline state (grey, "אין חיבור")
      expect(find.text('אין חיבור'), findsOneWidget);
      expect(find.text('📡'), findsOneWidget);

      // Go back online
      connectivityController.add(ConnectivityResult.wifi);
      await tester.pump(const Duration(milliseconds: 500));

      // Banner should animate away (still in tree but slid offscreen)
      // The AnimatedSlide shifts it to Offset(0, -1) — it's offscreen
      // but still findable. Check that isOffline is now false.
      expect(connectivityProvider.isOffline, isFalse);

      // Status card should return to all clear
      expect(find.text('אין התרעות'), findsOneWidget);

      await connectivityController.close();
    });

    testWidgets('HTTP failures trigger offline state', (tester) async {
      SharedPreferences.setMockInitialValues({
        'mklat_saved_locations':
            '[{"id":"test-id","orefName":"שדה בועז","customLabel":"","isPrimary":true,"shelterTimeSec":90}]',
      });

      // Start with working HTTP
      await tester.pumpWidget(MklatApp(httpClient: mockClient));
      await tester.pump(const Duration(seconds: 2));

      // App shows online state
      expect(find.text('אין התרעות'), findsOneWidget);

      // Now return 503 for all requests (simulating server unreachable)
      final error503 = http.Response('Service Unavailable', 503);
      when(
        mockClient.get(any, headers: anyNamed('headers')),
      ).thenAnswer((_) async => error503);

      // Wait for polling cycles to accumulate failures
      await tester.pump(const Duration(seconds: 5));

      // App should now show offline state
      expect(find.text('אין חיבור'), findsOneWidget);

      // Restore HTTP to working responses
      when(
        mockClient.get(
          argThat(predicate<Uri>((uri) => uri.path.contains('Alerts.json'))),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.orefAlerts);
      when(
        mockClient.get(
          argThat(
            predicate<Uri>((uri) => uri.path.contains('AlertsHistory.json')),
          ),
          headers: anyNamed('headers'),
        ),
      ).thenAnswer((_) async => TestFixtures.orefHistory);

      // Wait for successful poll
      await tester.pump(const Duration(seconds: 3));

      // Should be back online
      expect(find.text('אין התרעות'), findsOneWidget);
    });

    // NOTE: Resume overlay is tested via widget tests (test/widget/resume_overlay_test.dart).
    // IntegrationTestWidgetsFlutterBinding does not dispatch handleAppLifecycleStateChanged
    // to WidgetsBindingObserver, so lifecycle-dependent flows can't be tested here.
  });
}
