import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/widgets/news_list_item.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('NewsListItem', () {
    Widget buildTestWidget(NewsItem newsItem) {
      return MaterialApp(
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
        (NewsSource.walla, 'W'),
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
  });
}
