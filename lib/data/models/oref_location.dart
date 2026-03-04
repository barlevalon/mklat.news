/// OREF location with shelter time information
class OrefLocation {
  /// Location name in Hebrew (label_he from Districts)
  final String name;

  /// Numeric ID
  final String id;

  /// Hash identifier (value field)
  final String hashId;

  /// Region group ID (1-37)
  final int areaId;

  /// Region name (e.g., 'תל אביב', 'ירושלים')
  final String areaName;

  /// Shelter time in seconds (migun_time)
  /// Values: 0, 15, 30, 45, 60, or 90
  /// Null if from fallback source without shelter data
  final int? shelterTimeSec;

  const OrefLocation({
    required this.name,
    required this.id,
    required this.hashId,
    required this.areaId,
    required this.areaName,
    this.shelterTimeSec,
  });

  factory OrefLocation.fromJson(Map<String, dynamic> json) {
    return OrefLocation(
      name: json['name'] as String,
      id: json['id'] as String,
      hashId: json['hashId'] as String,
      areaId: json['areaId'] as int,
      areaName: json['areaName'] as String,
      shelterTimeSec: json['shelterTimeSec'] as int?,
    );
  }

  /// Creates an OrefLocation from a GetDistricts.aspx response entry.
  factory OrefLocation.fromDistricts(Map<String, dynamic> json) {
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
  factory OrefLocation.fromCitiesFallback(Map<String, dynamic> json) {
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

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'id': id,
      'hashId': hashId,
      'areaId': areaId,
      'areaName': areaName,
      'shelterTimeSec': shelterTimeSec,
    };
  }

  /// Get formatted shelter time for display
  String? get shelterTimeDisplay {
    if (shelterTimeSec == null) return null;
    if (shelterTimeSec == 0) return 'מיידי';
    if (shelterTimeSec! < 60) return '$shelterTimeSec שניות';
    if (shelterTimeSec == 60) return 'דקה';
    if (shelterTimeSec == 90) return 'דקה וחצי';
    if (shelterTimeSec! >= 120) {
      final minutes = shelterTimeSec! ~/ 60;
      return '$minutes דקות';
    }
    // Fallback for other values (unlikely given OREF data: 0, 15, 30, 45, 60, 90)
    final minutes = shelterTimeSec! ~/ 60;
    final seconds = shelterTimeSec! % 60;
    if (seconds == 0) return '$minutes דקות';
    return '$minutes:${seconds.toString().padLeft(2, '0')} דקות';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrefLocation &&
          runtimeType == other.runtimeType &&
          hashId == other.hashId;

  @override
  int get hashCode => hashId.hashCode;

  @override
  String toString() =>
      'OrefLocation(name: $name, areaName: $areaName, '
      'shelterTimeSec: $shelterTimeSec)';
}
