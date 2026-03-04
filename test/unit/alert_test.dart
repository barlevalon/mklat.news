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
        desc: 'היכנסו למרחב המוגן',
        time: testTime,
        category: 1,
      );

      final json = alert.toJson();
      expect(json['id'], 'test-123');
      expect(json['location'], 'תל אביב - מרכז');
      expect(json['title'], 'ירי רקטות וטילים');
      expect(json['desc'], 'היכנסו למרחב המוגן');
      expect(json['category'], 1);
      expect(json['time'], testTime.toIso8601String());

      final fromJson = Alert.fromJson(json);
      expect(fromJson.id, alert.id);
      expect(fromJson.location, alert.location);
      expect(fromJson.title, alert.title);
      expect(fromJson.desc, alert.desc);
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

  group('Alert.fromOrefActive', () {
    test('maps basic Alerts.json format correctly', () {
      final alertJson = {
        'id': '133721700000000000',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'desc': 'היכנסו למרחב המוגן',
        'data': ['תל אביב - מרכז העיר', 'חיפה - מערב'],
      };

      final alert = Alert.fromOrefActive(alertJson, 'תל אביב - מרכז העיר');

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

      final alert = Alert.fromOrefActive(alertJson, 'Location');

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

      final alert = Alert.fromOrefActive(alertJson, 'Location');

      expect(alert.desc, 'היכנסו למרחב המוגן');
    });

    test('desc can be null', () {
      final alertJson = {
        'id': '123',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['Location'],
      };

      final alert = Alert.fromOrefActive(alertJson, 'Location');

      expect(alert.desc, null);
    });

    test('time is set to DateTime.now()', () {
      final alertJson = {
        'id': '123',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['Location'],
      };

      final before = DateTime.now();
      final alert = Alert.fromOrefActive(alertJson, 'Location');
      final after = DateTime.now();

      expect(
        alert.time.isAfter(before) || alert.time.isAtSameMomentAs(before),
        true,
      );
      expect(
        alert.time.isBefore(after) || alert.time.isAtSameMomentAs(after),
        true,
      );
    });

    test('ID synthesis is unique per location', () {
      final alertJson = {
        'id': '133721700000000000',
        'cat': 1,
        'title': 'ירי רקטות וטילים',
        'data': ['תל אביב - מרכז העיר', 'חיפה - מערב'],
      };

      final alert1 = Alert.fromOrefActive(alertJson, 'תל אביב - מרכז העיר');
      final alert2 = Alert.fromOrefActive(alertJson, 'חיפה - מערב');

      expect(alert1.id, isNot(equals(alert2.id)));
      expect(alert1.id, contains('133721700000000000'));
      expect(alert2.id, contains('133721700000000000'));
    });
  });

  group('Alert.fromOrefHistory', () {
    test('maps basic AlertsHistory.json format correctly', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'גבעת הראל',
        'category': 1,
      };

      final alert = Alert.fromOrefHistory(json);

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

      final alert = Alert.fromOrefHistory(json);

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

      final alert = Alert.fromOrefHistory(json);

      expect(alert.location, 'גבעת הראל');
    });

    test('category maps correctly', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'חדירת כלי טיס עוין',
        'data': 'Location',
        'category': 2,
      };

      final alert = Alert.fromOrefHistory(json);

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

      final alert = Alert.fromOrefHistory(json);

      expect(alert.id, '2026-03-04 14:09:32_גבעת הראל');
    });

    test('desc is null for history entries', () {
      final json = {
        'alertDate': '2026-03-04 14:09:32',
        'title': 'ירי רקטות וטילים',
        'data': 'Location',
        'category': 1,
      };

      final alert = Alert.fromOrefHistory(json);

      expect(alert.desc, null);
    });
  });
}
