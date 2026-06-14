import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/codecs/news_item_json_codec.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('NewsSourceJsonCodec', () {
    test('serializes and deserializes JSON', () {
      for (final source in NewsSource.values) {
        final json = NewsSourceJsonCodec.toJson(source);
        expect(json, source.name);

        final fromJson = NewsSourceJsonCodec.fromJson(json);
        expect(fromJson, source);
      }
    });

    test('fromJson defaults to ynet for unknown value', () {
      expect(NewsSourceJsonCodec.fromJson('unknown'), NewsSource.ynet);
    });
  });

  group('NewsItemJsonCodec', () {
    test('serializes and deserializes JSON', () {
      final testTime = DateTime(2026, 3, 4, 14, 30);
      final item = NewsItem(
        id: 'news-123',
        title: 'פיצוץ נשמע באזור הדרום',
        description: 'תקציר קצר',
        link: 'https://ynet.co.il/article/123',
        pubDate: testTime,
        source: NewsSource.ynet,
      );

      final json = NewsItemJsonCodec.toJson(item);
      expect(json['id'], 'news-123');
      expect(json['title'], 'פיצוץ נשמע באזור הדרום');
      expect(json['description'], 'תקציר קצר');
      expect(json['link'], 'https://ynet.co.il/article/123');
      expect(json['source'], 'ynet');
      expect(json['pubDate'], testTime.toIso8601String());

      final fromJson = NewsItemJsonCodec.fromJson(json);
      expect(fromJson.id, item.id);
      expect(fromJson.title, item.title);
      expect(fromJson.description, item.description);
      expect(fromJson.source, item.source);
    });
  });
}
