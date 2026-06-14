import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/mappers/rss_news_item_mapper.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:xml/xml.dart';

void main() {
  group('RssNewsItemMapper', () {
    XmlElement itemFrom(String xml) {
      return XmlDocument.parse(
        '<rss><channel>$xml</channel></rss>',
      ).findAllElements('item').single;
    }

    test('maps required RSS fields into NewsItem', () {
      final item = itemFrom('''
        <item>
          <title>כותרת</title>
          <link>https://example.com/1</link>
          <pubDate>Thu, 04 Mar 2026 14:30:00 +0200</pubDate>
        </item>
      ''');

      final newsItem = RssNewsItemMapper.toNewsItem(item, NewsSource.ynet);

      expect(newsItem, isNotNull);
      expect(newsItem!.id, 'https://example.com/1');
      expect(newsItem.title, 'כותרת');
      expect(newsItem.link, 'https://example.com/1');
      expect(newsItem.source, NewsSource.ynet);
      expect(newsItem.pubDate, DateTime.utc(2026, 3, 4, 12, 30));
    });

    test('strips CDATA and HTML from title and description', () {
      final item = itemFrom('''
        <item>
          <title><![CDATA[Title with <special> chars]]></title>
          <link>https://example.com/1</link>
          <description><![CDATA[<p>Paragraph with <b>bold</b></p>]]></description>
          <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
        </item>
      ''');

      final newsItem = RssNewsItemMapper.toNewsItem(item, NewsSource.maariv);

      expect(newsItem!.title, 'Title with <special> chars');
      expect(newsItem.description, 'Paragraph with bold');
    });

    test('returns null when title is missing', () {
      final item = itemFrom('''
        <item>
          <link>https://example.com/1</link>
          <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
        </item>
      ''');

      expect(RssNewsItemMapper.toNewsItem(item, NewsSource.ynet), null);
    });

    test('returns null when link is missing', () {
      final item = itemFrom('''
        <item>
          <title>כותרת</title>
          <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
        </item>
      ''');

      expect(RssNewsItemMapper.toNewsItem(item, NewsSource.ynet), null);
    });

    test('invalid or empty dates become epoch', () {
      final item = itemFrom('''
        <item>
          <title>כותרת</title>
          <link>https://example.com/1</link>
          <pubDate>bad date</pubDate>
        </item>
      ''');

      final newsItem = RssNewsItemMapper.toNewsItem(item, NewsSource.haaretz);

      expect(newsItem!.pubDate, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
