import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:mklat/data/services/rss_news_service.dart';
import 'package:mklat/core/api_endpoints.dart';

import '../mocks/mock_http_client.dart';

void main() {
  group('RssNewsService', () {
    late MockHttpClient mockHttpClient;
    late RssNewsService service;

    setUp(() {
      mockHttpClient = MockHttpClient();
      service = RssNewsService(mockHttpClient);
    });

    // Sample RSS XML for tests
    final validYnetRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Ynet Breaking News</title>
    <item>
      <title><![CDATA[פיצוץ נשמע באזור הדרום]]></title>
      <link>https://www.ynet.co.il/article/123</link>
      <description><![CDATA[<p>תקציר קצר של הכתבה</p>]]></description>
      <pubDate>Thu, 04 Mar 2026 14:30:00 +0200</pubDate>
    </item>
    <item>
      <title><![CDATA[כותרת שנייה]]></title>
      <link>https://www.ynet.co.il/article/456</link>
      <pubDate>Thu, 04 Mar 2026 14:00:00 +0200</pubDate>
    </item>
  </channel>
</rss>''';

    final validMaarivRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Maariv News</title>
    <item>
      <title><![CDATA[חדשות מעריב]]></title>
      <link>https://www.maariv.co.il/article/789</link>
      <description><![CDATA[<div>תיאור החדשות</div>]]></description>
      <pubDate>Thu, 04 Mar 2026 13:45:00 +0200</pubDate>
    </item>
  </channel>
</rss>''';

    final validWallaRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Walla News</title>
    <item>
      <title><![CDATA[חדשות וואלה]]></title>
      <link>https://www.walla.co.il/article/111</link>
      <description><![CDATA[<b>תיאור</b>]]></description>
      <pubDate>Thu, 04 Mar 2026 14:30:00 GMT</pubDate>
    </item>
  </channel>
</rss>''';

    final validHaaretzRss = '''<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
  <channel>
    <title>Haaretz News</title>
    <item>
      <title><![CDATA[חדשות הארץ]]></title>
      <link>https://www.haaretz.co.il/article/222</link>
      <pubDate>Thu, 04 Mar 2026 12:00:00 +0200</pubDate>
    </item>
  </channel>
</rss>''';

    test('basic RSS parsing returns correct NewsItem list', () async {
      when(
        mockHttpClient.get(ApiEndpoints.rssYnet),
      ).thenAnswer((_) async => validYnetRss);
      when(mockHttpClient.get(ApiEndpoints.rssMaariv)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title></title>
  <link></link>
</item></channel></rss>''',
      );
      when(mockHttpClient.get(ApiEndpoints.rssWalla)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel></channel></rss>''',
      );
      when(mockHttpClient.get(ApiEndpoints.rssHaaretz)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel></channel></rss>''',
      );

      final result = await service.fetchAllNews();

      expect(result.length, 2);
      expect(result[0].title, 'פיצוץ נשמע באזור הדרום');
      expect(result[0].link, 'https://www.ynet.co.il/article/123');
      expect(result[0].source, NewsSource.ynet);
      expect(result[0].description, 'תקציר קצר של הכתבה');
    });

    test('CDATA stripping removes CDATA wrappers', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title><![CDATA[Title with <special> chars]]></title>
  <link>https://example.com/1</link>
  <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
</item></channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      expect(result[0].title, 'Title with <special> chars');
    });

    test('HTML stripping removes HTML tags from descriptions', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title>Test</title>
  <link>https://example.com/1</link>
  <description><![CDATA[<p>Paragraph with <b>bold</b> and <a href="x">link</a></p>]]></description>
  <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
</item></channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      expect(result[0].description, 'Paragraph with bold and link');
    });

    test('Walla timezone bug - GMT dates parsed as local time', () async {
      when(
        mockHttpClient.get(ApiEndpoints.rssYnet),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => validWallaRss);
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      // Walla date "14:30:00 GMT" should be parsed as local time (14:30), not converted
      expect(result[0].pubDate.hour, 14);
      expect(result[0].pubDate.minute, 30);
    });

    test(
      'multiple feeds combined and sorted by pubDate newest-first',
      () async {
        when(
          mockHttpClient.get(ApiEndpoints.rssYnet),
        ).thenAnswer((_) async => validYnetRss);
        when(
          mockHttpClient.get(ApiEndpoints.rssMaariv),
        ).thenAnswer((_) async => validMaarivRss);
        when(
          mockHttpClient.get(ApiEndpoints.rssWalla),
        ).thenAnswer((_) async => validWallaRss);
        when(
          mockHttpClient.get(ApiEndpoints.rssHaaretz),
        ).thenAnswer((_) async => validHaaretzRss);

        final result = await service.fetchAllNews();

        expect(result.length, 5);
        // Should be sorted by pubDate descending (newest first)
        // Ynet item 1: 14:30:00 +0200
        // Walla: 14:30:00 GMT (treated as local 14:30)
        // Ynet item 2: 14:00:00 +0200
        // Maariv: 13:45:00 +0200
        // Haaretz: 12:00:00 +0200

        // First item should be one of the 14:30 items (Ynet or Walla)
        // Note: Dates are converted to UTC, so 14:30 +0200 becomes 12:30 UTC
        expect(result[0].source, anyOf(NewsSource.ynet, NewsSource.walla));

        // Last item should be Haaretz at 12:00 (10:00 UTC)
        expect(result.last.source, NewsSource.haaretz);
      },
    );

    test('individual feed failure returns empty for that feed only', () async {
      when(
        mockHttpClient.get(ApiEndpoints.rssYnet),
      ).thenAnswer((_) async => validYnetRss);
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenThrow(Exception('Network error'));
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenThrow(Exception('Network error'));
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenThrow(Exception('Network error'));

      final result = await service.fetchAllNews();

      expect(result.length, 2); // Only Ynet items
      expect(result.every((item) => item.source == NewsSource.ynet), true);
    });

    test('all feeds fail returns empty list', () async {
      when(
        mockHttpClient.get(ApiEndpoints.rssYnet),
      ).thenThrow(Exception('Network error'));
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenThrow(Exception('Network error'));
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenThrow(Exception('Network error'));
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenThrow(Exception('Network error'));

      final result = await service.fetchAllNews();

      expect(result, isEmpty);
    });

    test('invalid XML returns empty list for that feed', () async {
      when(
        mockHttpClient.get(ApiEndpoints.rssYnet),
      ).thenAnswer((_) async => 'not valid xml');
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => validMaarivRss);
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1); // Only Maariv item
      expect(result[0].source, NewsSource.maariv);
    });

    test('missing title or link filters out item', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel>
  <item>
    <title>Has title</title>
    <link></link>
    <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
  </item>
  <item>
    <title></title>
    <link>https://example.com/1</link>
    <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
  </item>
  <item>
    <title>Valid item</title>
    <link>https://example.com/2</link>
    <pubDate>Thu, 04 Mar 2026 11:00:00 +0200</pubDate>
  </item>
</channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      expect(result[0].title, 'Valid item');
    });

    test('empty description returns null', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title>Test</title>
  <link>https://example.com/1</link>
  <description></description>
  <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
</item></channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      expect(result[0].description, isNull);
    });

    test('missing description element returns null', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title>Test</title>
  <link>https://example.com/1</link>
  <pubDate>Thu, 04 Mar 2026 10:00:00 +0200</pubDate>
</item></channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 1);
      expect(result[0].description, isNull);
    });

    test('empty pubDate returns DateTime.now', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel><item>
  <title>Test</title>
  <link>https://example.com/1</link>
  <pubDate></pubDate>
</item></channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final before = DateTime.now();
      final result = await service.fetchAllNews();
      final after = DateTime.now();

      expect(result.length, 1);
      expect(
        result[0].pubDate.isAfter(before.subtract(Duration(seconds: 1))),
        true,
      );
      expect(result[0].pubDate.isBefore(after.add(Duration(seconds: 1))), true);
    });

    test('RFC 2822 date parsing with various timezone formats', () async {
      when(mockHttpClient.get(ApiEndpoints.rssYnet)).thenAnswer(
        (_) async => '''<?xml version="1.0"?>
<rss><channel>
  <item>
    <title>UTC test</title>
    <link>https://example.com/1</link>
    <pubDate>Thu, 04 Mar 2026 12:00:00 UTC</pubDate>
  </item>
  <item>
    <title>Offset test</title>
    <link>https://example.com/2</link>
    <pubDate>04 Mar 2026 15:30:00 +0200</pubDate>
  </item>
  <item>
    <title>No timezone</title>
    <link>https://example.com/3</link>
    <pubDate>04 Mar 2026 10:00:00</pubDate>
  </item>
</channel></rss>''',
      );
      when(
        mockHttpClient.get(ApiEndpoints.rssMaariv),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssWalla),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');
      when(
        mockHttpClient.get(ApiEndpoints.rssHaaretz),
      ).thenAnswer((_) async => '<rss><channel></channel></rss>');

      final result = await service.fetchAllNews();

      expect(result.length, 3);
    });
  });
}
