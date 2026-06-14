/// OREF location with shelter time information
class OrefLocation {
  /// Location name from Districts/cities data
  final String name;

  /// Numeric ID
  final String id;

  /// Hash identifier (value field)
  final String hashId;

  /// Region group ID (1-37)
  final int areaId;

  /// Region name from OREF data
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
