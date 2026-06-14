import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/mappers/oref_history_alert_mapper.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('OrefHistoryAlertMapper', () {
    test('maps basic AlertsHistory.json format correctly', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'גבעת הראל',
        'category': 1,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.location, 'גבעת הראל');
      expect(alert.title, 'ירי רקטות וטילים');
      expect(alert.category, 1);
    });

    test('alertDate is parsed correctly', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'Location',
        'category': 1,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.time.year, 2026);
      expect(alert.time.month, 3);
      expect(alert.time.day, 4);
      expect(alert.time.hour, 14);
      expect(alert.time.minute, 9);
      expect(alert.time.second, 32);
    });

    test('data string maps to location', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'גבעת הראל',
        'category': 1,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.location, 'גבעת הראל');
    });

    test('category maps correctly', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'חדירת כלי טיס עוין',
        'data': 'Location',
        'category': 2,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.category, 2);
      expect(alert.type, AlertCategory.uav);
    });

    test('ID is synthesized from alertDate and data', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'גבעת הראל',
        'category': 1,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.id, '2026-03-04 14:09:32_גבעת הראל');
    });

    test('desc is null for history entries', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'Location',
        'category': 1,
      };

      final alert = OrefHistoryAlertMapper.toAlert(json);

      expect(alert.desc, null);
    });
  });
}
