import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/codecs/alert_json_codec.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertJsonCodec', () {
    test('serializes and deserializes JSON', () {
      final testTime = DateTime(2026, 3, 4, 14, 30);
      final alert = Alert(
        id: 'test-123',
        location: 'תל אביב - מרכז',
        title: 'ירי רקטות וטילים',
        desc: 'היכנסו למרחב המוגן',
        time: testTime,
        category: 1,
      );

      final json = AlertJsonCodec.toJson(alert);
      expect(json['id'], 'test-123');
      expect(json['location'], 'תל אביב - מרכז');
      expect(json['title'], 'ירי רקטות וטילים');
      expect(json['desc'], 'היכנסו למרחב המוגן');
      expect(json['category'], 1);
      expect(json['time'], testTime.toIso8601String());

      final fromJson = AlertJsonCodec.fromJson(json);
      expect(fromJson.id, alert.id);
      expect(fromJson.location, alert.location);
      expect(fromJson.title, alert.title);
      expect(fromJson.desc, alert.desc);
      expect(fromJson.category, alert.category);
      expect(fromJson.time, alert.time);
    });
  });
}
