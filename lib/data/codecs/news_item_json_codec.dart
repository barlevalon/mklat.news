import '../models/news_item.dart';

class NewsSourceJsonCodec {
  const NewsSourceJsonCodec._();

  static String toJson(NewsSource source) => source.name;

  static NewsSource fromJson(String json) {
    return NewsSource.values.firstWhere(
      (source) => source.name == json,
      orElse: () => NewsSource.ynet,
    );
  }
}

class NewsItemJsonCodec {
  const NewsItemJsonCodec._();

  static NewsItem fromJson(Map<String, dynamic> json) {
    return NewsItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      link: json['link'] as String,
      pubDate: DateTime.parse(json['pubDate'] as String),
      source: NewsSourceJsonCodec.fromJson(json['source'] as String),
    );
  }

  static Map<String, dynamic> toJson(NewsItem item) {
    return {
      'id': item.id,
      'title': item.title,
      'description': item.description,
      'link': item.link,
      'pubDate': item.pubDate.toIso8601String(),
      'source': NewsSourceJsonCodec.toJson(item.source),
    };
  }
}
