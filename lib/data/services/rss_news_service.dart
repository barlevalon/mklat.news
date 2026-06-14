import 'package:xml/xml.dart';
import '../../core/api_endpoints.dart';
import '../mappers/rss_news_item_mapper.dart';
import '../models/news_item.dart';
import 'http_client.dart';

class _RssFeed {
  final String url;
  final NewsSource source;

  const _RssFeed(this.url, this.source);
}

class _FeedFetchResult {
  final List<NewsItem> items;
  final Object? error;

  const _FeedFetchResult.success(this.items) : error = null;
  const _FeedFetchResult.failure(this.error) : items = const [];

  bool get isSuccess => error == null;
}

/// RSS news service that fetches and parses headlines from 3 Israeli news sources.
class RssNewsService {
  final HttpClient _httpClient;

  RssNewsService(this._httpClient);

  static const _feeds = [
    _RssFeed(ApiEndpoints.rssYnet, NewsSource.ynet),
    _RssFeed(ApiEndpoints.rssMaariv, NewsSource.maariv),
    _RssFeed(ApiEndpoints.rssHaaretz, NewsSource.haaretz),
  ];

  /// Fetch news from all RSS sources.
  /// Returns combined list sorted by pubDate (newest first).
  /// Parse errors return empty for that feed. Network exceptions are tolerated
  /// per feed, but if no feed is reachable the first network exception is
  /// rethrown so the UI can show a news error.
  Future<List<NewsItem>> fetchAllNews() async {
    final results = await Future.wait(_feeds.map(_fetchFeedSafely));

    final reachableFeedCount = results
        .where((result) => result.isSuccess)
        .length;
    if (reachableFeedCount == 0 && results.isNotEmpty) {
      throw results.first.error!;
    }

    final allItems = results.expand((result) => result.items).toList();
    allItems.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allItems;
  }

  Future<_FeedFetchResult> _fetchFeedSafely(_RssFeed feed) async {
    try {
      return _FeedFetchResult.success(await _fetchFeed(feed.url, feed.source));
    } catch (e) {
      return _FeedFetchResult.failure(e);
    }
  }

  /// Fetch and parse a single RSS feed. Returns [] on parse error.
  /// Network exceptions propagate to polling manager.
  Future<List<NewsItem>> _fetchFeed(String url, NewsSource source) async {
    // Let network exceptions (HttpException, SocketException, TimeoutException) propagate
    final body = await _httpClient.get(url);
    try {
      return _parseRssFeed(body, source);
    } catch (e) {
      return []; // Parse errors return empty
    }
  }

  /// Parse RSS XML into NewsItem list.
  List<NewsItem> _parseRssFeed(String xmlStr, NewsSource source) {
    try {
      final document = XmlDocument.parse(xmlStr);
      final items = document.findAllElements('item');

      return items
          .map((item) => RssNewsItemMapper.toNewsItem(item, source))
          .whereType<NewsItem>()
          .toList();
    } catch (e) {
      return [];
    }
  }
}
