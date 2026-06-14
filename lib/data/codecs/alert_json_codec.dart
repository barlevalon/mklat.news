import '../models/alert.dart';

class AlertJsonCodec {
  const AlertJsonCodec._();

  static Alert fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] as String,
      location: json['location'] as String,
      title: json['title'] as String,
      desc: json['desc'] as String?,
      time: DateTime.parse(json['time'] as String),
      category: json['category'] as int,
    );
  }

  static Map<String, dynamic> toJson(Alert alert) {
    return {
      'id': alert.id,
      'location': alert.location,
      'title': alert.title,
      'desc': alert.desc,
      'time': alert.time.toIso8601String(),
      'category': alert.category,
    };
  }
}
