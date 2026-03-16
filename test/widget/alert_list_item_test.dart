import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/core/app_theme.dart';
import 'package:mklat/presentation/widgets/alert_list_item.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertListItem', () {
    Widget buildTestWidget(Alert alert) {
      return MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: AlertListItem(alert: alert)),
        ),
      );
    }

    Widget buildDarkModeTestWidget(Alert alert) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: AlertListItem(alert: alert)),
        ),
      );
    }

    testWidgets('singular minute: shows "לפני דקה" not "לפני 1 דקות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(minutes: 1, seconds: 30)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      // Should show singular form
      expect(find.textContaining('לפני דקה'), findsOneWidget);
      // Should NOT show "1 דקות"
      expect(find.textContaining('1 דקות'), findsNothing);
    });

    testWidgets('singular hour: shows "לפני שעה" not "לפני 1 שעות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      // Should show singular form
      expect(find.textContaining('לפני שעה'), findsOneWidget);
      // Should NOT show "1 שעות"
      expect(find.textContaining('1 שעות'), findsNothing);
    });

    testWidgets('plural minutes: shows "לפני 5 דקות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(minutes: 5)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      expect(find.textContaining('לפני 5 דקות'), findsOneWidget);
    });

    testWidgets('plural hours: shows "לפני 3 שעות"', (
      WidgetTester tester,
    ) async {
      final alert = Alert(
        id: 'test_1',
        location: 'רחובות',
        title: 'ירי רקטות וטילים',
        time: DateTime.now().subtract(const Duration(hours: 3)),
        category: 1,
      );

      await tester.pumpWidget(buildTestWidget(alert));

      expect(find.textContaining('לפני 3 שעות'), findsOneWidget);
    });

    testWidgets(
      'dark mode: location text uses theme color instead of hardcoded black54',
      (WidgetTester tester) async {
        final alert = Alert(
          id: 'test_dark',
          location: 'רחובות',
          title: 'ירי רקטות וטילים',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          category: 1,
        );

        await tester.pumpWidget(buildDarkModeTestWidget(alert));

        // Find the location text widget
        final locationFinder = find.text('רחובות');
        expect(locationFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(locationFinder);
        final actualColor = textWidget.style?.color;

        // In dark mode, should NOT be the hardcoded light-mode black54
        expect(actualColor, isNot(equals(Colors.black54)));

        // Should use a theme-appropriate color (onSurface with opacity or similar)
        final expectedColor = AppTheme.darkTheme.colorScheme.onSurface
            .withValues(alpha: 0.7);
        expect(actualColor, equals(expectedColor));
      },
    );
    testWidgets(
      'dark mode: timestamp text uses theme color instead of hardcoded black38',
      (WidgetTester tester) async {
        final alert = Alert(
          id: 'test_dark_timestamp',
          location: 'רחובות',
          title: 'ירי רקטות וטילים',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          category: 1,
        );

        await tester.pumpWidget(buildDarkModeTestWidget(alert));

        // Find the timestamp text widget ("לפני 5 דקות")
        final timestampFinder = find.textContaining('לפני 5 דקות');
        expect(timestampFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(timestampFinder);
        final actualColor = textWidget.style?.color;

        // In dark mode, should NOT be the hardcoded light-mode black38
        expect(actualColor, isNot(equals(Colors.black38)));

        // Should use a theme-appropriate color (onSurface with opacity or similar)
        final expectedColor = AppTheme.darkTheme.colorScheme.onSurface
            .withValues(alpha: 0.7);
        expect(actualColor, equals(expectedColor));
      },
    );
    testWidgets(
      'dark mode: card border uses theme color instead of hardcoded grey.shade200',
      (WidgetTester tester) async {
        final alert = Alert(
          id: 'test_dark_border',
          location: 'רחובות',
          title: 'ירי רקטות וטילים',
          time: DateTime.now().subtract(const Duration(minutes: 5)),
          category: 1,
        );

        await tester.pumpWidget(buildDarkModeTestWidget(alert));

        // Find the Card widget
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        final cardWidget = tester.widget<Card>(cardFinder);
        final shape = cardWidget.shape as RoundedRectangleBorder;
        final actualBorderColor = shape.side.color;

        // In dark mode, should NOT be the hardcoded light-mode grey.shade200
        expect(actualBorderColor, isNot(equals(Colors.grey.shade200)));

        // Should use a theme-appropriate color (outline variant or similar)
        final expectedBorderColor = AppTheme.darkTheme.colorScheme.outline;
        expect(actualBorderColor, equals(expectedBorderColor));
      },
    );
  });
}
