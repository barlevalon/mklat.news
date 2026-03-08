import 'package:xml/xml.dart';
import '../../core/api_endpoints.dart';
import '../models/news_item.dart';
import 'http_client.dart';

/// RSS news service that fetches and parses headlines from 3 Israeli news sources.
class RssNewsService {
  final HttpClient _httpClient;

  RssNewsService(this._httpClient);

  /// Fetch news from all RSS sources.
  /// Returns combined list sorted by pubDate (newest first).
  /// Parse errors return empty for that feed; network exceptions propagate.
  Future<List<NewsItem>> fetchAllNews() async {
    final results = await Future.wait([
      _fetchFeed(ApiEndpoints.rssYnet, NewsSource.ynet),
      _fetchFeed(ApiEndpoints.rssMaariv, NewsSource.maariv),
      _fetchFeed(ApiEndpoints.rssHaaretz, NewsSource.haaretz),
    ]);

    final allItems = results.expand((items) => items).toList();
    allItems.sort((a, b) => b.pubDate.compareTo(a.pubDate));
    return allItems;
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
          .map((item) {
            final title = _extractText(item, 'title');
            final link = _extractText(item, 'link');
            final description = _extractText(item, 'description');
            final pubDateStr = _extractText(item, 'pubDate');

            if (title.isEmpty || link.isEmpty) return null;

            final pubDate = _parsePubDate(pubDateStr, source);

            return NewsItem(
              id: link,
              title: _stripCdata(title),
              description: description.isNotEmpty
                  ? _stripHtml(_stripCdata(description)).trim()
                  : null,
              link: link,
              pubDate: pubDate,
              source: source,
            );
          })
          .whereType<NewsItem>()
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Parse RFC 2822 date format commonly used in RSS feeds.
  /// Example: "Thu, 04 Mar 2026 14:30:00 +0200"
  /// Example: "Thu, 04 Mar 2026 14:30:00 GMT"
  DateTime _parsePubDate(String dateStr, NewsSource source) {
    if (dateStr.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      var cleaned = dateStr.trim();

      return _parseRfc2822(cleaned);
    } catch (e) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  static final _months = {
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };

  /// Parse RFC 2822 date string to DateTime.
  /// Handles: "Thu, 04 Mar 2026 14:30:00 +0200"
  /// Also handles: "04 Mar 2026 14:30:00"
  DateTime _parseRfc2822(String input) {
    // Remove day name prefix if present (e.g., "Thu, ")
    final cleaned = input.replaceFirst(RegExp(r'^[A-Za-z]{3},?\s*'), '');

    // Parse: "04 Mar 2026 14:30:00 +0200" or "04 Mar 2026 14:30:00"
    final parts = cleaned.split(RegExp(r'\s+'));
    // parts[0] = "04", parts[1] = "Mar", parts[2] = "2026", parts[3] = "14:30:00", parts[4] = "+0200" (optional)

    final day = int.parse(parts[0]);
    final month = _months[parts[1].toLowerCase()]!;
    final year = int.parse(parts[2]);

    final timeParts = parts[3].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

    if (parts.length > 4) {
      // Has timezone offset like "+0200" or "GMT"
      final tz = parts[4];
      if (tz == 'GMT' || tz == 'UTC') {
        return DateTime.utc(year, month, day, hour, minute, second);
      }
      // Parse numeric offset like "+0200" or "-0500"
      final sign = tz.startsWith('-') ? -1 : 1;
      final offsetStr = tz.replaceFirst(RegExp(r'[+-]'), '');
      final offsetHours = int.parse(offsetStr.substring(0, 2));
      final offsetMinutes = int.parse(offsetStr.substring(2, 4));
      final offset =
          Duration(hours: offsetHours, minutes: offsetMinutes) * sign;
      return DateTime.utc(
        year,
        month,
        day,
        hour,
        minute,
        second,
      ).subtract(offset);
    }

    // No timezone — treat as local time
    return DateTime(year, month, day, hour, minute, second);
  }

  /// Strip CDATA wrapper from RSS content.
  /// Input: "<![CDATA[Actual content]]>" → Output: "Actual content"
  String _stripCdata(String input) {
    return input.replaceAllMapped(
      RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
      (match) => match.group(1) ?? '',
    );
  }

  /// Strip HTML tags from a string.
  /// Input: "<p>Hello <b>world</b></p>" → Output: "Hello world"
  String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  /// Extract text content of a named element from an RSS item.
  String _extractText(XmlElement item, String elementName) {
    final element = item.findElements(elementName).firstOrNull;
    if (element == null) return '';
    return element.innerText;
  }
}
