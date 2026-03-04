/// Categories for alert types
enum AlertCategory {
  /// Category 1 - ירי רקטות וטילים (rockets/missiles)
  rockets,

  /// Category 2 - חדירת כלי טיס עוין (hostile UAV)
  uav,

  /// Category 13 - האירוע הסתיים (event ended/clearance)
  clearance,

  /// Category 14 - התרעה צפויה (imminent warning)
  imminent,

  /// Other categories (earthquake, tsunami, hazmat, etc.)
  other,
}

extension AlertCategoryExtension on AlertCategory {
  /// Get the OREF category number
  int get categoryNumber {
    switch (this) {
      case AlertCategory.rockets:
        return 1;
      case AlertCategory.uav:
        return 2;
      case AlertCategory.clearance:
        return 13;
      case AlertCategory.imminent:
        return 14;
      case AlertCategory.other:
        return 0;
    }
  }

  /// Get category from OREF category number
  static AlertCategory fromCategoryNumber(int number) {
    switch (number) {
      case 1:
        return AlertCategory.rockets;
      case 2:
        return AlertCategory.uav;
      case 13:
        return AlertCategory.clearance;
      case 14:
        return AlertCategory.imminent;
      default:
        return AlertCategory.other;
    }
  }

  /// Get Hebrew display title
  String get hebrewTitle {
    switch (this) {
      case AlertCategory.rockets:
        return 'ירי רקטות וטילים';
      case AlertCategory.uav:
        return 'חדירת כלי טיס עוין';
      case AlertCategory.clearance:
        return 'האירוע הסתיים';
      case AlertCategory.imminent:
        return 'התרעה צפויה';
      case AlertCategory.other:
        return 'התרעה';
    }
  }

  /// Get instruction text for this alert type
  String? get instruction {
    switch (this) {
      case AlertCategory.rockets:
      case AlertCategory.uav:
        return 'היכנסו למרחב המוגן';
      case AlertCategory.clearance:
        return 'ניתן לצאת מהמרחב המוגן';
      case AlertCategory.imminent:
        return 'התרעות צפויות בדקות הקרובות';
      case AlertCategory.other:
        return null;
    }
  }
}

/// Alert model representing an OREF alert event
class Alert {
  /// Unique alert identifier
  final String id;

  /// Location name in Hebrew (from `data` field)
  final String location;

  /// Alert type title in Hebrew
  final String title;

  /// Timestamp of the alert
  final DateTime time;

  /// OREF category number (1, 2, 13, 14, etc.)
  final int category;

  /// Derived category enum
  AlertCategory get type => AlertCategoryExtension.fromCategoryNumber(category);

  const Alert({
    required this.id,
    required this.location,
    required this.title,
    required this.time,
    required this.category,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      location: json['location'] as String,
      title: json['title'] as String,
      time: DateTime.parse(json['time'] as String),
      category: json['category'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location': location,
      'title': title,
      'time': time.toIso8601String(),
      'category': category,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alert &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          location == other.location &&
          time == other.time;

  @override
  int get hashCode => Object.hash(id, location, time);

  @override
  String toString() =>
      'Alert(id: $id, location: $location, title: $title, '
      'category: $category, time: $time)';
}
