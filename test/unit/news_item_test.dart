import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('NewsSource', () {
    test('displayName returns correct names', () {
      expect(NewsSource.ynet.displayName, 'Ynet');
      expect(NewsSource.maariv.displayName, 'Maariv');
      expect(NewsSource.mako.displayName, 'Mako');
      expect(NewsSource.haaretz.displayName, 'Haaretz');
    });

    test('domain returns correct domains', () {
      expect(NewsSource.ynet.domain, 'ynet.co.il');
      expect(NewsSource.maariv.domain, 'maariv.co.il');
      expect(NewsSource.mako.domain, 'mako.co.il');
      expect(NewsSource.haaretz.domain, 'haaretz.co.il');
    });

    test('fromDomain parses domains correctly', () {
      expect(NewsSourceExtension.fromDomain('ynet.co.il'), NewsSource.ynet);
      expect(
        NewsSourceExtension.fromDomain('www.maariv.co.il'),
        NewsSource.maariv,
      );
      expect(NewsSourceExtension.fromDomain('RSS.MAKO.CO.IL'), NewsSource.mako);
      expect(
        NewsSourceExtension.fromDomain('haaretz.co.il'),
        NewsSource.haaretz,
      );
    });

    test('fromDomain defaults to ynet for unknown domains', () {
      expect(NewsSourceExtension.fromDomain('unknown.com'), NewsSource.ynet);
    });

    test('serialization to/from JSON', () {
      for (final source in NewsSource.values) {
        final json = source.toJson();
        expect(json, source.name);

        final fromJson = NewsSourceExtension.fromJson(json);
        expect(fromJson, source);
      }
    });

    test('fromJson defaults to ynet for unknown value', () {
      expect(NewsSourceExtension.fromJson('unknown'), NewsSource.ynet);
    });
  });

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

    test('serialization to/from JSON', () {
      final item = NewsItem(
        id: 'news-123',
        title: 'פיצוץ נשמע באזור הדרום',
        description: 'תקציר קצר',
        link: 'https://ynet.co.il/article/123',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      final json = item.toJson();
      expect(json['id'], 'news-123');
      expect(json['title'], 'פיצוץ נשמע באזור הדרום');
      expect(json['description'], 'תקציר קצר');
      expect(json['link'], 'https://ynet.co.il/article/123');
      expect(json['source'], 'ynet');
      expect(json['pubDate'], testTime.toIso8601String());

      final fromJson = NewsItem.fromJson(json);
      expect(fromJson.id, item.id);
      expect(fromJson.title, item.title);
      expect(fromJson.description, item.description);
      expect(fromJson.source, item.source);
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
        source: NewsSource.mako, // Different source
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
