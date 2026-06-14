import 'package:xml/xml.dart';
import '../models/news_item.dart';

class RssNewsItemMapper {
  const RssNewsItemMapper._();

  static NewsItem? toNewsItem(XmlElement item, NewsSource source) {
    final title = _extractText(item, 'title');
    final link = _extractText(item, 'link');
    final description = _extractText(item, 'description');
    final pubDateStr = _extractText(item, 'pubDate');

    if (title.isEmpty || link.isEmpty) return null;

    return NewsItem(
      id: link,
      title: _stripCdata(title),
      description: description.isNotEmpty
          ? _stripHtml(_stripCdata(description)).trim()
          : null,
      link: link,
      pubDate: _parsePubDate(pubDateStr),
      source: source,
    );
  }

  static DateTime _parsePubDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    try {
      return _parseRfc2822(dateStr.trim());
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

  static DateTime _parseRfc2822(String input) {
    final cleaned = input.replaceFirst(RegExp(r'^[A-Za-z]{3},?\s*'), '');
    final parts = cleaned.split(RegExp(r'\s+'));

    final day = int.parse(parts[0]);
    final month = _months[parts[1].toLowerCase()]!;
    final year = int.parse(parts[2]);

    final timeParts = parts[3].split(':');
    final hour = int.parse(timeParts[0]);
    final minute = int.parse(timeParts[1]);
    final second = timeParts.length > 2 ? int.parse(timeParts[2]) : 0;

    if (parts.length > 4) {
      final tz = parts[4];
      if (tz == 'GMT' || tz == 'UTC') {
        return DateTime.utc(year, month, day, hour, minute, second);
      }

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

    return DateTime(year, month, day, hour, minute, second);
  }

  static String _stripCdata(String input) {
    return input.replaceAllMapped(
      RegExp(r'<!\[CDATA\[(.*?)\]\]>', dotAll: true),
      (match) => match.group(1) ?? '',
    );
  }

  static String _stripHtml(String input) {
    return input.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static String _extractText(XmlElement item, String elementName) {
    final element = item.findElements(elementName).firstOrNull;
    if (element == null) return '';
    return element.innerText;
  }
}
