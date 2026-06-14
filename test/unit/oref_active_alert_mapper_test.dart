import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/mappers/oref_active_alert_mapper.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('OrefActiveAlertMapper', () {
    final activeTime = DateTime(2026, 3, 4, 14, 30);

    test('maps basic Alerts.json format correctly', () {
      final alertJson = {
        'id': '133721700000000000',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'desc': 'היכנסו למרחב המוגן',
        'data': ['תל אביב - מרכז העיר', 'חיפה - מערב'],
      };

      final alert = OrefActiveAlertMapper.toAlert(
        alertJson,
        'תל אביב - מרכז העיר',
        time: activeTime,
      );

      expect(alert.location, 'תל אביב - מרכז העיר');
      expect(alert.title, 'ירי רקטות וטילים');
      expect(alert.category, 1);
    });

    test('cat field maps to category', () {
      final alertJson = {
        'id': '123',
        'cat': 2,
        'title': 'חדירת כלי טיס עוין',
        'data': ['Location'],
      };

      final alert = OrefActiveAlertMapper.toAlert(
        alertJson,
        'Location',
        time: activeTime,
      );

      expect(alert.category, 2);
      expect(alert.type, AlertCategory.uav);
    });

    test('desc field is captured', () {
      final alertJson = {
        'id': '123',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'desc': 'היכנסו למרחב המוגן',
        'data': ['Location'],
      };

      final alert = OrefActiveAlertMapper.toAlert(
        alertJson,
        'Location',
        time: activeTime,
      );

      expect(alert.desc, 'היכנסו למרחב המוגן');
    });

    test('desc can be null', () {
      final alertJson = {
        'id': '123',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['Location'],
      };

      final alert = OrefActiveAlertMapper.toAlert(
        alertJson,
        'Location',
        time: activeTime,
      );

      expect(alert.desc, null);
    });

    test('time is provided by caller', () {
      final alertJson = {
        'id': '123',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['Location'],
      };

      final alert = OrefActiveAlertMapper.toAlert(
        alertJson,
        'Location',
        time: activeTime,
      );

      expect(alert.time, activeTime);
    });

    test('ID synthesis is unique per location', () {
      final alertJson = {
        'id': '133721700000000000',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['תל אביב - מרכז העיר', 'חיפה - מערב'],
      };

      final alert1 = OrefActiveAlertMapper.toAlert(
        alertJson,
        'תל אביב - מרכז העיר',
        time: activeTime,
      );
      final alert2 = OrefActiveAlertMapper.toAlert(
        alertJson,
        'חיפה - מערב',
        time: activeTime,
      );

      expect(alert1.id, isNot(equals(alert2.id)));
      expect(alert1.id, contains('133721700000000000'));
      expect(alert2.id, contains('133721700000000000'));
    });
  });
}
