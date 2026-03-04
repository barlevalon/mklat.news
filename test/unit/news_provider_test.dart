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

    test('onError with no existing news: sets error', () {
      provider.onError('news', Exception('Network error'));

      expect(provider.errorMessage, 'שגיאה בטעינת חדשות');
    });

    test('onError with existing news: keeps news, no error message', () {
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
      provider.onError('news', Exception('Network error'));

      expect(provider.newsItems.length, 1);
      expect(provider.errorMessage, isNull);
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
