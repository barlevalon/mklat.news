/// News sources enum
enum NewsSource { ynet, maariv, haaretz }

/// News item from RSS feed
class NewsItem {
  /// Unique identifier (often derived from URL)
  final String id;

  /// Article title/headline
  final String title;

  /// Article description/summary (optional)
  final String? description;

  /// Link to full article
  final String link;

  /// Publication date
  final DateTime pubDate;

  /// News source
  final NewsSource source;

  const NewsItem({
    required this.id,
    required this.title,
    this.description,
    required this.link,
    required this.pubDate,
    required this.source,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NewsItem(title: $title, source: ${source.name}, '
      'pubDate: $pubDate)';
}
