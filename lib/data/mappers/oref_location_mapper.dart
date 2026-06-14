import '../models/oref_location.dart';

class OrefLocationMapper {
  const OrefLocationMapper._();

  /// Creates an OrefLocation from a GetDistricts.aspx response entry.
  static OrefLocation fromDistricts(Map<String, dynamic> json) {
    return OrefLocation(
      name: (json['label_he'] ?? json['label']) as String,
      id: json['id'].toString(),
      hashId: json['value'] as String,
      areaId: json['areaid'] as int,
      areaName: json['areaname'] as String,
      shelterTimeSec: json['migun_time'] as int?,
    );
  }

  /// Creates an OrefLocation from a cities_heb.json fallback entry.
  static OrefLocation fromCitiesFallback(Map<String, dynamic> json) {
    final label = json['label'].toString();
    final parts = label.split('|');
    final hebrewName = parts.first.trim();
    final areaName = parts.length > 1 ? parts[1].trim() : '';
    return OrefLocation(
      name: hebrewName,
      id: json['id'].toString(),
      hashId: json['cityAlId'] as String,
      areaId: json['areaid'] as int,
      areaName: areaName,
      shelterTimeSec: null,
    );
  }
}
