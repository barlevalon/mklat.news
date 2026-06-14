import 'dart:io';

/// Writes compact semantic fixtures for device integration tests.
///
/// Full captured raw-response fixtures live under test/fixtures/responses/ and
/// are exercised by host-side fixture tests. Device UI tests only need stable,
/// small responses that drive the app flows without embedding megabytes of
/// binary data as Dart source.
void main() {
  final outputFile = File('integration_test/test_fixtures.dart');
  outputFile.parent.createSync(recursive: true);
  outputFile.writeAsStringSync(_fixtureSource);
  final format = Process.runSync('dart', ['format', outputFile.path]);
  if (format.exitCode != 0) {
    stderr.write(format.stderr);
    exit(format.exitCode);
  }
}

const _fixtureSource = r"""import 'dart:convert';
import 'package:http/http.dart' as http;

class TestFixtures {
  static http.Response get orefAlerts => _jsonResponse('\uFEFF\r\n');

  static http.Response get orefHistory => _jsonResponse('[]');

  static http.Response get orefDistricts => _jsonResponse(
    jsonEncode([
      _district('763', 'שדה בועז', 'יהודה ושומרון', 90),
      _district('1001', 'רחובות', 'השפלה', 60),
      _district('1002', 'תל אביב - מרכז העיר', 'דן', 90),
      _district('1003', 'ירושלים', 'ירושלים', 90),
      _district('1004', 'חיפה - מערב', 'חיפה', 60),
    ]),
  );

  static http.Response get orefCities => _jsonResponse(
    jsonEncode([
      _city('763', 'שדה בועז|יהודה ושומרון'),
      _city('1001', 'רחובות|השפלה'),
      _city('1002', 'תל אביב - מרכז העיר|דן'),
      _city('1003', 'ירושלים|ירושלים'),
    ]),
  );

  static http.Response get rssYnet => _xmlResponse(
    _rss('Ynet', [
      _item(
        title: 'עדכון ביטחוני מ-ynet',
        link: 'https://www.ynet.co.il/news/article/security-update',
        description: 'מבזק חדשות קצר',
        pubDate: 'Sat, 13 Jun 2026 18:30:00 +0300',
      ),
    ]),
  );

  static http.Response get rssMaariv => _xmlResponse(
    _rss('Maariv', [
      _item(
        title: 'מבזק ממעריב',
        link: 'https://www.maariv.co.il/news/article-1',
        description: 'כותרת בדיקה',
        pubDate: 'Sat, 13 Jun 2026 18:20:00 +0300',
      ),
    ]),
  );

  static http.Response get rssHaaretz => _xmlResponse(
    _rss('Haaretz', [
      _item(
        title: 'עדכון מהארץ',
        link: 'https://www.haaretz.co.il/news/1.0000000',
        description: 'טקסט קצר',
        pubDate: 'Sat, 13 Jun 2026 18:10:00 +0300',
      ),
    ]),
  );

  static Map<String, Object?> _district(
    String id,
    String name,
    String areaName,
    int shelterTimeSec,
  ) {
    return {
      'id': id,
      'label': name,
      'label_he': name,
      'value': 'hash-$id',
      'areaid': 1,
      'areaname': areaName,
      'migun_time': shelterTimeSec,
    };
  }

  static Map<String, Object?> _city(String id, String label) {
    return {
      'id': id,
      'label': label,
      'cityAlId': 'city-$id',
      'areaid': 1,
    };
  }

  static String _rss(String title, List<String> items) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0"><channel><title>$title</title>${items.join()}</channel></rss>''';
  }

  static String _item({
    required String title,
    required String link,
    required String description,
    required String pubDate,
  }) {
    return '''<item>
<title><![CDATA[$title]]></title>
<link>$link</link>
<description><![CDATA[$description]]></description>
<pubDate>$pubDate</pubDate>
</item>''';
  }

  static http.Response _jsonResponse(String body) {
    return http.Response.bytes(
      utf8.encode(body),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );
  }

  static http.Response _xmlResponse(String body) {
    return http.Response.bytes(
      utf8.encode(body),
      200,
      headers: {'content-type': 'application/rss+xml; charset=utf-8'},
    );
  }
}
""";
