import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/news_item.dart';
import 'package:mklat/presentation/models/news_source_presentation.dart';

void main() {
  group('NewsSourcePresentation', () {
    test('maps display names', () {
      expect(
        NewsSourcePresentation.fromSource(NewsSource.ynet).displayName,
        'Ynet',
      );
      expect(
        NewsSourcePresentation.fromSource(NewsSource.maariv).displayName,
        'Maariv',
      );
      expect(
        NewsSourcePresentation.fromSource(NewsSource.haaretz).displayName,
        'Haaretz',
      );
    });

    test('maps domains', () {
      expect(
        NewsSourcePresentation.fromSource(NewsSource.ynet).domain,
        'ynet.co.il',
      );
      expect(
        NewsSourcePresentation.fromSource(NewsSource.maariv).domain,
        'maariv.co.il',
      );
      expect(
        NewsSourcePresentation.fromSource(NewsSource.haaretz).domain,
        'haaretz.co.il',
      );
    });

    test('fromDomain parses domains correctly', () {
      expect(NewsSourcePresentation.fromDomain('ynet.co.il'), NewsSource.ynet);
      expect(
        NewsSourcePresentation.fromDomain('www.maariv.co.il'),
        NewsSource.maariv,
      );
      expect(
        NewsSourcePresentation.fromDomain('haaretz.co.il'),
        NewsSource.haaretz,
      );
    });

    test('fromDomain defaults to ynet for unknown domains', () {
      expect(NewsSourcePresentation.fromDomain('unknown.com'), NewsSource.ynet);
    });
  });
}
