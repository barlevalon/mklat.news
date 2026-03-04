import 'package:uuid/uuid.dart';

/// User-saved location with custom label
class SavedLocation {
  /// Unique identifier (UUID)
  final String id;

  /// Exact OREF location name (matches label_he)
  final String orefName;

  /// User's custom label (e.g., "בית", "עבודה")
  /// If empty or null, display should fall back to orefName
  final String customLabel;

  /// Whether this is the primary location
  final bool isPrimary;

  /// Cached shelter time from OrefLocation
  /// Nullable because fallback location list may not include shelter times
  final int? shelterTimeSec;

  const SavedLocation({
    required this.id,
    required this.orefName,
    this.customLabel = '',
    this.isPrimary = false,
    this.shelterTimeSec,
  });

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    return SavedLocation(
      id: json['id'] as String,
      orefName: json['orefName'] as String,
      customLabel: json['customLabel'] as String? ?? '',
      isPrimary: json['isPrimary'] as bool? ?? false,
      shelterTimeSec: json['shelterTimeSec'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orefName': orefName,
      'customLabel': customLabel,
      'isPrimary': isPrimary,
      'shelterTimeSec': shelterTimeSec,
    };
  }

  /// Get display label (custom if set, otherwise OREF name)
  String get displayLabel => customLabel.isNotEmpty ? customLabel : orefName;

  /// Create a new saved location with a generated ID
  factory SavedLocation.create({
    required String orefName,
    String customLabel = '',
    bool isPrimary = false,
    int? shelterTimeSec,
  }) {
    return SavedLocation(
      id: const Uuid().v4(),
      orefName: orefName,
      customLabel: customLabel,
      isPrimary: isPrimary,
      shelterTimeSec: shelterTimeSec,
    );
  }

  /// Create a copy with optional field changes
  SavedLocation copyWith({
    String? id,
    String? orefName,
    String? customLabel,
    bool? isPrimary,
    int? shelterTimeSec,
  }) {
    return SavedLocation(
      id: id ?? this.id,
      orefName: orefName ?? this.orefName,
      customLabel: customLabel ?? this.customLabel,
      isPrimary: isPrimary ?? this.isPrimary,
      shelterTimeSec: shelterTimeSec ?? this.shelterTimeSec,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedLocation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'SavedLocation(displayLabel: $displayLabel, orefName: $orefName, '
      'isPrimary: $isPrimary)';
}
