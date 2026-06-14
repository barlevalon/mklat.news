import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/models/oref_location.dart';

void main() {
  group('OrefLocation', () {
    test('constructs with all required fields', () {
      final location = OrefLocation(
        name: 'תל אביב - מרכז',
        id: '123',
        hashId: 'abc123',
        areaId: 5,
        areaName: 'תל אביב',
        shelterTimeSec: 90,
      );

      expect(location.name, 'תל אביב - מרכז');
      expect(location.id, '123');
      expect(location.hashId, 'abc123');
      expect(location.areaId, 5);
      expect(location.areaName, 'תל אביב');
      expect(location.shelterTimeSec, 90);
    });

    test('constructs without optional shelterTimeSec', () {
      final location = OrefLocation(
        name: 'תל אביב - מרכז',
        id: '123',
        hashId: 'abc123',
        areaId: 5,
        areaName: 'תל אביב',
      );

      expect(location.shelterTimeSec, null);
    });

    test('equality based on hashId', () {
      final loc1 = OrefLocation(
        name: 'Name A',
        id: '1',
        hashId: 'same-hash',
        areaId: 1,
        areaName: 'Area A',
        shelterTimeSec: 90,
      );

      final loc2 = OrefLocation(
        name: 'Name B', // Different name
        id: '2', // Different id
        hashId: 'same-hash', // Same hash
        areaId: 3, // Different area
        areaName: 'Area B', // Different area name
        shelterTimeSec: 30, // Different shelter time
      );

      final loc3 = OrefLocation(
        name: 'Name A',
        id: '1',
        hashId: 'different-hash',
        areaId: 1,
        areaName: 'Area A',
        shelterTimeSec: 90,
      );

      expect(loc1 == loc2, true); // Same hashId
      expect(loc1 == loc3, false); // Different hashId
    });
  });
}
