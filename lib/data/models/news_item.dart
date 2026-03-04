/// News sources enum
enum NewsSource { ynet, maariv, walla, haaretz }

extension NewsSourceExtension on NewsSource {
  /// Get display name for the source
  String get displayName {
    switch (this) {
      case NewsSource.ynet:
        return 'Ynet';
      case NewsSource.maariv:
        return 'Maariv';
      case NewsSource.walla:
        return 'Walla';
      case NewsSource.haaretz:
        return 'Haaretz';
    }
  }

  /// Get domain for favicon
  String get domain {
    switch (this) {
      case NewsSource.ynet:
        return 'ynet.co.il';
      case NewsSource.maariv:
        return 'maariv.co.il';
      case NewsSource.walla:
        return 'walla.co.il';
      case NewsSource.haaretz:
        return 'haaretz.co.il';
    }
  }

  /// Get source from domain string
  static NewsSource fromDomain(String domain) {
    final lowerDomain = domain.toLowerCase();
    if (lowerDomain.contains('ynet')) return NewsSource.ynet;
    if (lowerDomain.contains('maariv')) return NewsSource.maariv;
    if (lowerDomain.contains('walla')) return NewsSource.walla;
    if (lowerDomain.contains('haaretz')) return NewsSource.haaretz;
    return NewsSource.ynet; // default
  }

  /// Serialize to string
  String toJson() => name;

  /// Deserialize from string
  static NewsSource fromJson(String json) {
    return NewsSource.values.firstWhere(
      (e) => e.name == json,
      orElse: () => NewsSource.ynet,
    );
  }
}

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

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      link: json['link'] as String,
      pubDate: DateTime.parse(json['pubDate'] as String),
      source: NewsSourceExtension.fromJson(json['source'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'link': link,
      'pubDate': pubDate.toIso8601String(),
      'source': source.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'NewsItem(title: $title, source: ${source.displayName}, '
      'pubDate: $pubDate)';
}
