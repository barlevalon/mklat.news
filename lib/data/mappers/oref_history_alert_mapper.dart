import '../models/alert.dart';

class OrefHistoryAlertMapper {
  const OrefHistoryAlertMapper._();

  /// Maps one OREF AlertsHistory.json row into an Alert.
  static Alert toAlert(Map<String, dynamic> json) {
    return Alert(
      id: '${json['alertDate']}_${json['data']}',
      location: json['data'] as String,
      title: json['title'] as String,
      desc: null,
      time: DateTime.parse(json['alertDate'] as String),
      category: json['category'] as int,
    );
  }
}
