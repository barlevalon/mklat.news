import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('NewsItem', () {
    final testTime = DateTime(2026, 3, 4, 14, 30, 0);

    test('constructs with all required fields', () {
      final item = NewsItem(
        id: 'news-123',
        title: 'פיצוץ נשמע באזור הדרום',
        description: 'תקציר קצר של הכתבה',
        link: 'https://ynet.co.il/article/123',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      expect(item.id, 'news-123');
      expect(item.title, 'פיצוץ נשמע באזור הדרום');
      expect(item.description, 'תקציר קצר של הכתבה');
      expect(item.link, 'https://ynet.co.il/article/123');
      expect(item.pubDate, testTime);
      expect(item.source, NewsSource.ynet);
    });

    test('constructs without optional description', () {
      final item = NewsItem(
        id: 'news-123',
        title: 'כותרת',
        link: 'https://example.com',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      expect(item.description, null);
    });

    test('equality based on id', () {
      final item1 = NewsItem(
        id: 'same-id',
        title: 'Title A',
        link: 'https://a.com',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      final item2 = NewsItem(
        id: 'same-id',
        title: 'Title B', // Different title
        link: 'https://b.com', // Different link
        pubDate: DateTime(2025, 1, 1), // Different date
        source: NewsSource.haaretz, // Different source
      );

      final item3 = NewsItem(
        id: 'different-id',
        title: 'Title A',
        link: 'https://a.com',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      expect(item1 == item2, true); // Same id
      expect(item1 == item3, false); // Different id
    });
  });
}
