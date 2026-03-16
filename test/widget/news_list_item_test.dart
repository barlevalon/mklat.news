import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/widgets/news_list_item.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:mklat/core/app_theme.dart';

void main() {
  group('NewsListItem', () {
    Widget buildTestWidget(
      NewsItem newsItem, {
      ThemeMode themeMode = ThemeMode.light,
    }) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: NewsListItem(newsItem: newsItem)),
        ),
      );
    }

    testWidgets('renders headline and source name', (
      WidgetTester tester,
    ) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'פיצוץ נשמע באזור הדרום',
        description: 'תקציר קצר של הכתבה',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now().subtract(const Duration(minutes: 5)),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show the headline
      expect(find.text('פיצוץ נשמע באזור הדרום'), findsOneWidget);

      // Should show source name in the metadata line
      expect(find.textContaining('Ynet'), findsOneWidget);

      // Should show the source initial
      expect(find.text('Y'), findsOneWidget);
    });

    testWidgets('renders description when present', (
      WidgetTester tester,
    ) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת החדשה',
        description: 'תיאור מפורט של הכתבה',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now(),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show the description
      expect(find.text('תיאור מפורט של הכתבה'), findsOneWidget);
    });

    testWidgets('handles null description gracefully', (
      WidgetTester tester,
    ) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת בלי תיאור',
        description: null,
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now(),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show the headline
      expect(find.text('כותרת בלי תיאור'), findsOneWidget);

      // Should not crash and should still render
      expect(find.byType(NewsListItem), findsOneWidget);
    });

    testWidgets('renders different source initials correctly', (
      WidgetTester tester,
    ) async {
      final sources = [
        (NewsSource.ynet, 'Y'),
        (NewsSource.maariv, 'M'),
        (NewsSource.mako, 'M'),
        (NewsSource.haaretz, 'H'),
      ];

      for (final (source, initial) in sources) {
        final newsItem = NewsItem(
          id: '1',
          title: 'כותרת',
          link: 'https://example.com',
          pubDate: DateTime.now(),
          source: source,
        );

        await tester.pumpWidget(buildTestWidget(newsItem));

        // Should show the correct initial
        expect(find.text(initial), findsOneWidget);
      }
    });

    testWidgets('shows relative time', (WidgetTester tester) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now().subtract(const Duration(minutes: 5)),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show relative time
      expect(find.textContaining('לפני'), findsOneWidget);
      expect(find.textContaining('דקות'), findsOneWidget);
    });

    testWidgets('singular minute: shows "לפני דקה" not "לפני 1 דקות"', (
      WidgetTester tester,
    ) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now().subtract(
          const Duration(minutes: 1, seconds: 30),
        ),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show singular form
      expect(find.textContaining('לפני דקה'), findsOneWidget);
      // Should NOT show "1 דקות"
      expect(find.textContaining('1 דקות'), findsNothing);
    });

    testWidgets('singular hour: shows "לפני שעה" not "לפני 1 שעות"', (
      WidgetTester tester,
    ) async {
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should show singular form
      expect(find.textContaining('לפני שעה'), findsOneWidget);
      // Should NOT show "1 שעות"
      expect(find.textContaining('1 שעות'), findsNothing);
    });

    testWidgets('item with unparsable date does not show עכשיו', (
      WidgetTester tester,
    ) async {
      // An item whose pubDate would come from an unparsable RSS date
      // Currently _parsePubDate returns DateTime.now() as fallback,
      // which displays as "עכשיו" — this is wrong
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.fromMillisecondsSinceEpoch(
          0,
        ), // epoch sentinel = unparsable
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should NOT show "עכשיו" for an item with epoch sentinel date
      expect(find.textContaining('עכשיו'), findsNothing);
      // Should still show the source name
      expect(find.textContaining('Ynet'), findsOneWidget);
    });

    testWidgets('item with future date does not show עכשיו', (
      WidgetTester tester,
    ) async {
      // An item with a future pubDate (e.g. from Walla timezone bug)
      final newsItem = NewsItem(
        id: '1',
        title: 'כותרת',
        link: 'https://ynet.co.il/article/1',
        pubDate: DateTime.now().add(const Duration(hours: 1)),
        source: NewsSource.ynet,
      );

      await tester.pumpWidget(buildTestWidget(newsItem));

      // Should NOT show "עכשיו" for a future-dated item
      expect(find.textContaining('עכשיו'), findsNothing);
      // Should still show the source name
      expect(find.textContaining('Ynet'), findsOneWidget);
    });

    testWidgets(
      'description text uses theme color in dark mode, not hardcoded black54',
      (WidgetTester tester) async {
        final newsItem = NewsItem(
          id: '1',
          title: 'כותרת החדשה',
          description: 'תיאור מפורט של הכתבה',
          link: 'https://ynet.co.il/article/1',
          pubDate: DateTime.now(),
          source: NewsSource.ynet,
        );

        await tester.pumpWidget(
          buildTestWidget(newsItem, themeMode: ThemeMode.dark),
        );

        // Find the description text widget
        final descriptionFinder = find.text('תיאור מפורט של הכתבה');
        expect(descriptionFinder, findsOneWidget);

        // Get the Text widget and check its style color
        final textWidget = tester.widget<Text>(descriptionFinder);
        final color = textWidget.style?.color;

        // In dark mode, the description should NOT use hardcoded Colors.black54
        // which would be invisible. It should use a theme-appropriate color.
        expect(
          color,
          isNot(equals(Colors.black54)),
          reason:
              'Description text in dark mode should not use hardcoded Colors.black54',
        );
      },
    );
    testWidgets(
      'metadata line uses theme color in dark mode, not hardcoded black38',
      (WidgetTester tester) async {
        final newsItem = NewsItem(
          id: '1',
          title: 'כותרת החדשה',
          link: 'https://ynet.co.il/article/1',
          pubDate: DateTime.now().subtract(const Duration(minutes: 5)),
          source: NewsSource.ynet,
        );

        await tester.pumpWidget(
          buildTestWidget(newsItem, themeMode: ThemeMode.dark),
        );

        // Find the metadata line containing 'Ynet' and relative time
        final metadataFinder = find.textContaining('Ynet');
        expect(metadataFinder, findsOneWidget);

        // Get the Text widget and check its style color
        final textWidget = tester.widget<Text>(metadataFinder);
        final color = textWidget.style?.color;

        // In dark mode, the metadata should NOT use hardcoded Colors.black38
        // which would be invisible. It should use a theme-appropriate color.
        expect(
          color,
          isNot(equals(Colors.black38)),
          reason:
              'Metadata line in dark mode should not use hardcoded Colors.black38',
        );
      },
    );

    testWidgets(
      'card border uses theme-derived color in dark mode, not hardcoded grey.shade200',
      (WidgetTester tester) async {
        final newsItem = NewsItem(
          id: '1',
          title: 'כותרת החדשה',
          link: 'https://ynet.co.il/article/1',
          pubDate: DateTime.now(),
          source: NewsSource.ynet,
        );

        await tester.pumpWidget(
          buildTestWidget(newsItem, themeMode: ThemeMode.dark),
        );

        // Find the Card widget
        final cardFinder = find.byType(Card);
        expect(cardFinder, findsOneWidget);

        // Get the Card and extract its shape border color
        final cardWidget = tester.widget<Card>(cardFinder);
        final shape = cardWidget.shape as RoundedRectangleBorder;
        final borderColor = shape.side.color;

        // In dark mode, the card border should NOT use hardcoded Colors.grey.shade200
        // which is too light for dark backgrounds. It should use a theme-appropriate color.
        expect(
          borderColor,
          isNot(equals(Colors.grey.shade200)),
          reason:
              'Card border in dark mode should not use hardcoded Colors.grey.shade200',
        );
      },
    );
  });
}
