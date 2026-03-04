import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/alert.dart';

void main() {
  group('AlertCategory', () {
    test('fromCategoryNumber returns correct category', () {
      expect(
        AlertCategoryExtension.fromCategoryNumber(1),
        AlertCategory.rockets,
      );
      expect(AlertCategoryExtension.fromCategoryNumber(2), AlertCategory.uav);
      expect(
        AlertCategoryExtension.fromCategoryNumber(13),
        AlertCategory.clearance,
      );
      expect(
        AlertCategoryExtension.fromCategoryNumber(14),
        AlertCategory.imminent,
      );
      expect(
        AlertCategoryExtension.fromCategoryNumber(99),
        AlertCategory.other,
      );
    });

    test('categoryNumber returns correct value', () {
      expect(AlertCategory.rockets.categoryNumber, 1);
      expect(AlertCategory.uav.categoryNumber, 2);
      expect(AlertCategory.clearance.categoryNumber, 13);
      expect(AlertCategory.imminent.categoryNumber, 14);
      expect(AlertCategory.other.categoryNumber, 0);
    });

    test('hebrewTitle returns correct Hebrew text', () {
      expect(AlertCategory.rockets.hebrewTitle, 'ירי רקטות וטילים');
      expect(AlertCategory.uav.hebrewTitle, 'חדירת כלי טיס עוין');
      expect(AlertCategory.clearance.hebrewTitle, 'האירוע הסתיים');
      expect(AlertCategory.imminent.hebrewTitle, 'התרעה צפויה');
      expect(AlertCategory.other.hebrewTitle, 'התרעה');
    });

    test('instruction returns correct text', () {
      expect(AlertCategory.rockets.instruction, 'היכנסו למרחב המוגן');
      expect(AlertCategory.uav.instruction, 'היכנסו למרחב המוגן');
      expect(AlertCategory.clearance.instruction, 'ניתן לצאת מהמרחב המוגן');
      expect(AlertCategory.imminent.instruction, 'התרעות צפויות בדקות הקרובות');
      expect(AlertCategory.other.instruction, null);
    });
  });

  group('Alert', () {
    final testTime = DateTime(2026, 3, 4, 14, 30, 0);

    test('constructs with all required fields', () {
      final alert = Alert(
        id: 'test-123',
        location: 'תל אביב - מרכז',
        title: 'ירי רקטות וטילים',
        time: testTime,
        category: 1,
      );

      expect(alert.id, 'test-123');
      expect(alert.location, 'תל אביב - מרכז');
      expect(alert.title, 'ירי רקטות וטילים');
      expect(alert.time, testTime);
      expect(alert.category, 1);
    });

    test('type property derives from category', () {
      final rocketAlert = Alert(
        id: '1',
        location: 'A',
        title: 'T',
        time: testTime,
        category: 1,
      );
      expect(rocketAlert.type, AlertCategory.rockets);

      final uavAlert = Alert(
        id: '2',
        location: 'B',
        title: 'T',
        time: testTime,
        category: 2,
      );
      expect(uavAlert.type, AlertCategory.uav);

      final clearanceAlert = Alert(
        id: '3',
        location: 'C',
        title: 'T',
        time: testTime,
        category: 13,
      );
      expect(clearanceAlert.type, AlertCategory.clearance);
    });

    test('serialization to/from JSON', () {
      final alert = Alert(
        id: 'test-123',
        location: 'תל אביב - מרכז',
        title: 'ירי רקטות וטילים',
        time: testTime,
        category: 1,
      );

      final json = alert.toJson();
      expect(json['id'], 'test-123');
      expect(json['location'], 'תל אביב - מרכז');
      expect(json['title'], 'ירי רקטות וטילים');
      expect(json['category'], 1);
      expect(json['time'], testTime.toIso8601String());

      final fromJson = Alert.fromJson(json);
      expect(fromJson.id, alert.id);
      expect(fromJson.location, alert.location);
      expect(fromJson.title, alert.title);
      expect(fromJson.category, alert.category);
      expect(fromJson.time, alert.time);
    });

    test('equality based on id, location, and time', () {
      final alert1 = Alert(
        id: 'same',
        location: 'same',
        title: 'Title A',
        time: testTime,
        category: 1,
      );

      final alert2 = Alert(
        id: 'same',
        location: 'same',
        title: 'Title B', // Different title
        time: testTime,
        category: 2, // Different category
      );

      final alert3 = Alert(
        id: 'different',
        location: 'same',
        title: 'Title A',
        time: testTime,
        category: 1,
      );

      expect(alert1 == alert2, true); // Same id, location, time
      expect(alert1 == alert3, false); // Different id
    });
  });
}
