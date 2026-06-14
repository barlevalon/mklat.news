import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/presentation/providers/news_provider.dart';
import 'package:mklat/data/models/news_item.dart';

void main() {
  group('NewsProvider', () {
    late NewsProvider provider;

    setUp(() {
      provider = NewsProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('initial state: loading, no news', () {
      expect(provider.isLoading, isTrue);
      expect(provider.newsItems, isEmpty);
      expect(provider.errorMessage, isNull);
      expect(provider.hasNews, isFalse);
    });

    test('onNewsData: updates items, clears loading', () {
      final items = [
        NewsItem(
          id: '1',
          title: 'חדשות ראשונות',
          link: 'https://example.com/1',
          pubDate: DateTime.now(),
          source: NewsSource.ynet,
        ),
        NewsItem(
          id: '2',
          title: 'חדשות שנייה',
          link: 'https://example.com/2',
          pubDate: DateTime.now(),
          source: NewsSource.maariv,
        ),
      ];

      provider.onNewsData(items);

      expect(provider.isLoading, isFalse);
      expect(provider.newsItems.length, 2);
      expect(provider.errorMessage, isNull);
      expect(provider.hasNews, isTrue);
    });

    test('onError with no existing news: stops loading and sets error', () {
      provider.onError(Exception('Network error'));

      expect(provider.isLoading, isFalse);
      expect(provider.errorMessage, 'שגיאה בטעינת חדשות');
      expect(provider.newsItems, isEmpty);
      expect(provider.hasNews, isFalse);
    });

    test('onError with existing news: stops loading, keeps news, no error', () {
      final items = [
        NewsItem(
          id: '1',
          title: 'חדשות ראשונות',
          link: 'https://example.com/1',
          pubDate: DateTime.now(),
          source: NewsSource.ynet,
        ),
      ];

      provider.onNewsData(items);
      provider.onError(Exception('Network error'));

      expect(provider.isLoading, isFalse);
      expect(provider.newsItems.length, 1);
      expect(provider.errorMessage, isNull);
    });

    test('onNewsData with partial RSS success clears prior all-feed error', () {
      provider.onError(Exception('All RSS feeds failed'));
      expect(provider.errorMessage, 'שגיאה בטעינת חדשות');

      final items = [
        NewsItem(
          id: 'maariv-1',
          title: 'חדשות ממעריב',
          link: 'https://example.com/maariv',
          pubDate: DateTime.now(),
          source: NewsSource.maariv,
        ),
        NewsItem(
          id: 'haaretz-1',
          title: 'חדשות מהארץ',
          link: 'https://example.com/haaretz',
          pubDate: DateTime.now(),
          source: NewsSource.haaretz,
        ),
      ];

      provider.onNewsData(items);

      expect(provider.isLoading, isFalse);
      expect(provider.newsItems, items);
      expect(provider.errorMessage, isNull);
      expect(provider.hasNews, isTrue);
    });

    test('hasNews: true when items exist', () {
      expect(provider.hasNews, isFalse);

      final items = [
        NewsItem(
          id: '1',
          title: 'חדשות ראשונות',
          link: 'https://example.com/1',
          pubDate: DateTime.now(),
          source: NewsSource.ynet,
        ),
      ];

      provider.onNewsData(items);

      expect(provider.hasNews, isTrue);
    });
  });
}
