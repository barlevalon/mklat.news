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

    test('shelterTimeDisplay formats correctly', () {
      final immediate = OrefLocation(
        name: 'A',
        id: '1',
        hashId: 'h1',
        areaId: 1,
        areaName: 'Area',
        shelterTimeSec: 0,
      );
      expect(immediate.shelterTimeDisplay, 'מיידי');

      final fifteenSec = OrefLocation(
        name: 'B',
        id: '2',
        hashId: 'h2',
        areaId: 1,
        areaName: 'Area',
        shelterTimeSec: 15,
      );
      expect(fifteenSec.shelterTimeDisplay, '15 שניות');

      final oneMinute = OrefLocation(
        name: 'C',
        id: '3',
        hashId: 'h3',
        areaId: 1,
        areaName: 'Area',
        shelterTimeSec: 60,
      );
      expect(oneMinute.shelterTimeDisplay, 'דקה');

      final ninetySec = OrefLocation(
        name: 'D',
        id: '4',
        hashId: 'h4',
        areaId: 1,
        areaName: 'Area',
        shelterTimeSec: 90,
      );
      expect(ninetySec.shelterTimeDisplay, 'דקה וחצי');

      final twoMinutes = OrefLocation(
        name: 'E',
        id: '5',
        hashId: 'h5',
        areaId: 1,
        areaName: 'Area',
        shelterTimeSec: 120,
      );
      expect(twoMinutes.shelterTimeDisplay, '2 דקות');
    });

    test('shelterTimeDisplay returns null when shelterTimeSec is null', () {
      final location = OrefLocation(
        name: 'A',
        id: '1',
        hashId: 'h1',
        areaId: 1,
        areaName: 'Area',
      );
      expect(location.shelterTimeDisplay, null);
    });

    test('serialization to/from JSON', () {
      final location = OrefLocation(
        name: 'תל אביב - מרכז',
        id: '123',
        hashId: 'abc123',
        areaId: 5,
        areaName: 'תל אביב',
        shelterTimeSec: 90,
      );

      final json = location.toJson();
      expect(json['name'], 'תל אביב - מרכז');
      expect(json['id'], '123');
      expect(json['hashId'], 'abc123');
      expect(json['areaId'], 5);
      expect(json['areaName'], 'תל אביב');
      expect(json['shelterTimeSec'], 90);

      final fromJson = OrefLocation.fromJson(json);
      expect(fromJson.name, location.name);
      expect(fromJson.id, location.id);
      expect(fromJson.hashId, location.hashId);
      expect(fromJson.shelterTimeSec, location.shelterTimeSec);
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

  group('OrefLocation.fromDistricts', () {
    test('maps complete Districts JSON entry correctly', () {
      final json = {
        'label': 'אבו גוש',
        'value': '6657AD46BF8FA430B022FF282B7A804B',
        'id': '511',
        'areaid': 5,
        'areaname': 'בית שמש',
        'label_he': 'אבו גוש',
        'migun_time': 90,
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.name, 'אבו גוש');
      expect(location.id, '511');
      expect(location.hashId, '6657AD46BF8FA430B022FF282B7A804B');
      expect(location.areaId, 5);
      expect(location.areaName, 'בית שמש');
      expect(location.shelterTimeSec, 90);
    });

    test('label_he takes precedence over label for name', () {
      final json = {
        'label': 'Abu Ghosh',
        'value': 'hash123',
        'id': '511',
        'areaid': 5,
        'areaname': 'בית שמש',
        'label_he': 'אבו גוש',
        'migun_time': 60,
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.name, 'אבו גוש');
    });

    test('falls back to label when label_he is missing', () {
      final json = {
        'label': 'Abu Ghosh',
        'value': 'hash123',
        'id': '511',
        'areaid': 5,
        'areaname': 'בית שמש',
        'migun_time': 60,
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.name, 'Abu Ghosh');
    });

    test('handles id as int', () {
      final json = {
        'label': 'Test',
        'value': 'hash123',
        'id': 511,
        'areaid': 5,
        'areaname': 'Area',
        'migun_time': 60,
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.id, '511');
    });

    test('handles id as string', () {
      final json = {
        'label': 'Test',
        'value': 'hash123',
        'id': '511',
        'areaid': 5,
        'areaname': 'Area',
        'migun_time': 60,
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.id, '511');
    });

    test('handles null migun_time', () {
      final json = {
        'label': 'Test',
        'value': 'hash123',
        'id': '511',
        'areaid': 5,
        'areaname': 'Area',
      };

      final location = OrefLocation.fromDistricts(json);

      expect(location.shelterTimeSec, null);
    });
  });

  group('OrefLocation.fromCitiesFallback', () {
    test('extracts Hebrew name from pipe-separated label', () {
      final json = {
        'label': 'אבו גוש|Abu Ghosh|أبو غوش',
        'value': '6657AD46BF8FA430B022FF282B7A804B',
        'id': '511',
        'areaid': 5,
        'areaname': 'בית שמש',
      };

      final location = OrefLocation.fromCitiesFallback(json);

      expect(location.name, 'אבו גוש');
    });

    test('maps all fields correctly', () {
      final json = {
        'label': 'תל אביב|Tel Aviv',
        'value': 'abc123',
        'id': '123',
        'areaid': 5,
        'areaname': 'תל אביב',
      };

      final location = OrefLocation.fromCitiesFallback(json);

      expect(location.name, 'תל אביב');
      expect(location.id, '123');
      expect(location.hashId, 'abc123');
      expect(location.areaId, 5);
      expect(location.areaName, 'תל אביב');
    });

    test('shelterTimeSec is always null for cities fallback', () {
      final json = {
        'label': 'Test',
        'value': 'hash123',
        'id': '1',
        'areaid': 1,
        'areaname': 'Area',
      };

      final location = OrefLocation.fromCitiesFallback(json);

      expect(location.shelterTimeSec, null);
    });

    test('handles id as int', () {
      final json = {
        'label': 'Test',
        'value': 'hash123',
        'id': 999,
        'areaid': 1,
        'areaname': 'Area',
      };

      final location = OrefLocation.fromCitiesFallback(json);

      expect(location.id, '999');
    });
  });
}
