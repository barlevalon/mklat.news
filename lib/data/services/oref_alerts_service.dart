import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../mappers/oref_active_alert_mapper.dart';
import '../models/alert.dart';
import 'http_client.dart';

class ActiveAlertFeedInvalidException implements Exception {
  final Object cause;
  final String bodyPreview;

  const ActiveAlertFeedInvalidException(this.cause, this.bodyPreview);

  @override
  String toString() =>
      'ActiveAlertFeedInvalidException: $cause; bodyPreview=$bodyPreview';
}

DateTime _defaultNow() => DateTime.now();

class OrefAlertsService {
  final HttpClient _httpClient;
  final DateTime Function() _now;

  OrefAlertsService(this._httpClient, {DateTime Function() now = _defaultNow})
    : _now = now;

  /// Fetch current active alerts.
  /// Returns a list of Alert objects (one per location in the alert).
  /// Returns empty list if no active alerts.
  /// Network and parse exceptions propagate to polling manager.
  Future<List<Alert>> fetchCurrentAlerts() async {
    // Let network exceptions (HttpException, SocketException, TimeoutException) propagate
    final body = await _httpClient.get(
      ApiEndpoints.orefAlerts,
      useOrefHeaders: true,
    );
    try {
      return _parseAlertsResponse(body);
    } on ActiveAlertFeedInvalidException {
      rethrow;
    } catch (e) {
      throw ActiveAlertFeedInvalidException(e, _bodyPreview(body));
    }
  }

  /// Parse the Alerts.json response body.
  /// The response is either:
  /// - Empty/whitespace (after BOM strip) = no alerts → return []
  /// - JSON object with {id, cat, title, desc, data: [...]} → return Alert per location
  List<Alert> _parseAlertsResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    try {
      final json = jsonDecode(trimmed);
      if (json is! Map<String, dynamic>) {
        throw const FormatException('Alerts.json root must be an object');
      }

      final data = json['data'];
      if (data is! List) {
        throw const FormatException('Alerts.json data must be a list');
      }
      if (data.isEmpty) return [];
      if (data.any((location) => location is! String)) {
        throw const FormatException('Alerts.json data entries must be strings');
      }

      final fetchedAt = _now();
      return data
          .cast<String>()
          .map(
            (location) =>
                OrefActiveAlertMapper.toAlert(json, location, time: fetchedAt),
          )
          .toList();
    } on ActiveAlertFeedInvalidException {
      rethrow;
    } catch (e) {
      throw ActiveAlertFeedInvalidException(e, _bodyPreview(body));
    }
  }

  String _bodyPreview(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 200) return normalized;
    return '${normalized.substring(0, 200)}…';
  }
}
