import 'package:flutter_test/flutter_test.dart';
import 'package:mklat/data/codecs/oref_location_cache_codec.dart';
import 'package:mklat/data/models/oref_location.dart';

void main() {
  group('OrefLocationCacheCodec', () {
    test('serializes and deserializes cache JSON', () {
      final location = OrefLocation(
        name: 'תל אביב - מרכז',
        id: '123',
        hashId: 'abc123',
        areaId: 5,
        areaName: 'תל אביב',
        shelterTimeSec: 90,
      );

      final json = OrefLocationCacheCodec.toJson(location);
      expect(json['name'], 'תל אביב - מרכז');
      expect(json['id'], '123');
      expect(json['hashId'], 'abc123');
      expect(json['areaId'], 5);
      expect(json['areaName'], 'תל אביב');
      expect(json['shelterTimeSec'], 90);

      final fromJson = OrefLocationCacheCodec.fromJson(json);
      expect(fromJson.name, location.name);
      expect(fromJson.id, location.id);
      expect(fromJson.hashId, location.hashId);
      expect(fromJson.shelterTimeSec, location.shelterTimeSec);
    });
  });
}
