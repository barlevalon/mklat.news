import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/saved_location.dart';

void main() {
  group('SavedLocation', () {
    test('constructs with all required fields', () {
      final location = SavedLocation(
        id: 'uuid-123',
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
        shelterTimeSec: 90,
      );

      expect(location.id, 'uuid-123');
      expect(location.orefName, 'תל אביב - מרכז');
      expect(location.customLabel, 'בית');
      expect(location.isPrimary, true);
      expect(location.shelterTimeSec, 90);
    });

    test('constructs with default values', () {
      final location = SavedLocation(
        id: 'uuid-123',
        orefName: 'תל אביב - מרכז',
      );

      expect(location.customLabel, '');
      expect(location.isPrimary, false);
      expect(location.shelterTimeSec, null);
    });

    test('displayLabel returns custom label when set', () {
      final location = SavedLocation(
        id: '1',
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
      );
      expect(location.displayLabel, 'בית');
    });

    test('displayLabel falls back to orefName when customLabel is empty', () {
      final location = SavedLocation(
        id: '1',
        orefName: 'תל אביב - מרכז',
        customLabel: '',
      );
      expect(location.displayLabel, 'תל אביב - מרכז');
    });

    test('create factory generates UUID and sets fields', () {
      final location = SavedLocation.create(
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
        shelterTimeSec: 90,
      );

      expect(location.id, isNotEmpty);
      expect(location.id.length, greaterThan(10)); // UUID length
      expect(location.orefName, 'תל אביב - מרכז');
      expect(location.customLabel, 'בית');
      expect(location.isPrimary, true);
      expect(location.shelterTimeSec, 90);
    });

    test('create generates unique IDs', () {
      final location1 = SavedLocation.create(orefName: 'A');
      final location2 = SavedLocation.create(orefName: 'B');

      expect(location1.id, isNot(equals(location2.id)));
    });

    test('copyWith creates copy with modified fields', () {
      final original = SavedLocation(
        id: 'uuid-123',
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: false,
        shelterTimeSec: 90,
      );

      final copy = original.copyWith(customLabel: 'עבודה', isPrimary: true);

      expect(copy.id, original.id); // Unchanged
      expect(copy.orefName, original.orefName); // Unchanged
      expect(copy.customLabel, 'עבודה'); // Changed
      expect(copy.isPrimary, true); // Changed
      expect(copy.shelterTimeSec, original.shelterTimeSec); // Unchanged
    });

    test('serialization to/from JSON', () {
      final location = SavedLocation(
        id: 'uuid-123',
        orefName: 'תל אביב - מרכז',
        customLabel: 'בית',
        isPrimary: true,
        shelterTimeSec: 90,
      );

      final json = location.toJson();
      expect(json['id'], 'uuid-123');
      expect(json['orefName'], 'תל אביב - מרכז');
      expect(json['customLabel'], 'בית');
      expect(json['isPrimary'], true);
      expect(json['shelterTimeSec'], 90);

      final fromJson = SavedLocation.fromJson(json);
      expect(fromJson.id, location.id);
      expect(fromJson.orefName, location.orefName);
      expect(fromJson.customLabel, location.customLabel);
      expect(fromJson.isPrimary, location.isPrimary);
      expect(fromJson.shelterTimeSec, location.shelterTimeSec);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'id': 'uuid-123', 'orefName': 'תל אביב - מרכז'};

      final location = SavedLocation.fromJson(json);
      expect(location.customLabel, '');
      expect(location.isPrimary, false);
      expect(location.shelterTimeSec, null);
    });

    test('equality based on id', () {
      final loc1 = SavedLocation(
        id: 'same-uuid',
        orefName: 'Name A',
        customLabel: 'Label A',
      );

      final loc2 = SavedLocation(
        id: 'same-uuid',
        orefName: 'Name B', // Different
        customLabel: 'Label B', // Different
        isPrimary: true, // Different
        shelterTimeSec: 60, // Different
      );

      final loc3 = SavedLocation(
        id: 'different-uuid',
        orefName: 'Name A',
        customLabel: 'Label A',
      );

      expect(loc1 == loc2, true); // Same id
      expect(loc1 == loc3, false); // Different id
    });
  });
}
