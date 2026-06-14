import '../models/alert.dart';

class OrefActiveAlertMapper {
  const OrefActiveAlertMapper._();

  /// Maps one location from an OREF Alerts.json entry into an Alert.
  /// The caller validates the feed shape and expands the entry's `data` list.
  static Alert toAlert(
    Map<String, dynamic> alertJson,
    String locationName, {
    required DateTime time,
  }) {
    return Alert(
      id: '${alertJson['id']}_${locationName.hashCode}',
      location: locationName,
      title: alertJson['title'] as String,
      desc: alertJson['desc'] as String?,
      time: time,
      category: alertJson['cat'] as int,
    );
  }
}
