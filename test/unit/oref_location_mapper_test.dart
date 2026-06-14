import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/mappers/oref_location_mapper.dart';

void main() {
  group('OrefLocationMapper.fromDistricts', () {
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

      final location = OrefLocationMapper.fromDistricts(json);

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

      final location = OrefLocationMapper.fromDistricts(json);

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

      final location = OrefLocationMapper.fromDistricts(json);

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

      final location = OrefLocationMapper.fromDistricts(json);

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

      final location = OrefLocationMapper.fromDistricts(json);

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

      final location = OrefLocationMapper.fromDistricts(json);

      expect(location.shelterTimeSec, null);
    });
  });

  group('OrefLocationMapper.fromCitiesFallback', () {
    test('extracts Hebrew name from pipe-separated label', () {
      final json = {
        'label': 'אבו גוש | אזור שפלת יהודה',
        'cityAlId': '6657AD46BF8FA430B022FF282B7A804B',
        'id': '511',
        'areaid': 5,
      };

      final location = OrefLocationMapper.fromCitiesFallback(json);

      expect(location.name, 'אבו גוש');
      expect(location.areaName, 'אזור שפלת יהודה');
    });

    test('handles label without pipe separator', () {
      final json = {
        'label': 'אזור תעשייה שחורת',
        'cityAlId': '124FC5752F86660B7458D50DCE51AE40',
        'id': '10',
        'areaid': 1,
      };

      final location = OrefLocationMapper.fromCitiesFallback(json);

      expect(location.name, 'אזור תעשייה שחורת');
      expect(location.areaName, '');
    });

    test('maps all fields correctly', () {
      final json = {
        'label': 'תל אביב | תל אביב יפו',
        'cityAlId': 'abc123',
        'id': '123',
        'areaid': 5,
      };

      final location = OrefLocationMapper.fromCitiesFallback(json);

      expect(location.name, 'תל אביב');
      expect(location.id, '123');
      expect(location.hashId, 'abc123');
      expect(location.areaId, 5);
      expect(location.areaName, 'תל אביב יפו');
    });

    test('shelterTimeSec is always null for cities fallback', () {
      final json = {
        'label': 'Test',
        'cityAlId': 'hash123',
        'id': '1',
        'areaid': 1,
      };

      final location = OrefLocationMapper.fromCitiesFallback(json);

      expect(location.shelterTimeSec, null);
    });

    test('handles id as int', () {
      final json = {
        'label': 'Test',
        'cityAlId': 'hash123',
        'id': 999,
        'areaid': 1,
      };

      final location = OrefLocationMapper.fromCitiesFallback(json);

      expect(location.id, '999');
    });
  });
}
