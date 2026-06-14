import '../../data/models/news_item.dart';

class NewsSourcePresentation {
  final String displayName;
  final String domain;

  const NewsSourcePresentation({
    required this.displayName,
    required this.domain,
  });

  factory NewsSourcePresentation.fromSource(NewsSource source) {
    switch (source) {
      case NewsSource.ynet:
        return const NewsSourcePresentation(
          displayName: 'Ynet',
          domain: 'ynet.co.il',
        );
      case NewsSource.maariv:
        return const NewsSourcePresentation(
          displayName: 'Maariv',
          domain: 'maariv.co.il',
        );
      case NewsSource.haaretz:
        return const NewsSourcePresentation(
          displayName: 'Haaretz',
          domain: 'haaretz.co.il',
        );
    }
  }

  static NewsSource fromDomain(String domain) {
    final lowerDomain = domain.toLowerCase();
    if (lowerDomain.contains('ynet')) return NewsSource.ynet;
    if (lowerDomain.contains('maariv')) return NewsSource.maariv;
    if (lowerDomain.contains('haaretz')) return NewsSource.haaretz;
    return NewsSource.ynet;
  }
}
