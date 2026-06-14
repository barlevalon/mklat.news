import '../models/oref_location.dart';

class OrefLocationCacheCodec {
  const OrefLocationCacheCodec._();

  static OrefLocation fromJson(Map<String, dynamic> json) {
    return OrefLocation(
      name: json['name'] as String,
      id: json['id'] as String,
      hashId: json['hashId'] as String,
      areaId: json['areaId'] as int,
      areaName: json['areaName'] as String,
      shelterTimeSec: json['shelterTimeSec'] as int?,
    );
  }

  static Map<String, dynamic> toJson(OrefLocation location) {
    return {
      'name': location.name,
      'id': location.id,
      'hashId': location.hashId,
      'areaId': location.areaId,
      'areaName': location.areaName,
      'shelterTimeSec': location.shelterTimeSec,
    };
  }
}
