import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../models/alert.dart';
import 'http_client.dart';

class OrefHistoryService {
  final HttpClient _httpClient;

  OrefHistoryService(this._httpClient);

  /// Fetch alert history.
  /// Returns a list of Alert objects from the last ~1 hour of events.
  /// Returns empty list on top-level parse error and skips malformed rows.
  /// Network exceptions propagate to polling manager.
  Future<List<Alert>> fetchAlertHistory() async {
    // Let network exceptions (HttpException, SocketException, TimeoutException) propagate
    final body = await _httpClient.get(
      ApiEndpoints.orefHistory,
      useOrefHeaders: true,
    );
    try {
      return _parseHistoryResponse(body);
    } catch (e) {
      return []; // Parse errors return empty
    }
  }

  /// Parse the AlertsHistory.json response body.
  /// Response is a JSON array of objects: [{alertDate, title, data, category}, ...]
  List<Alert> _parseHistoryResponse(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return [];

    try {
      final json = jsonDecode(trimmed);
      if (json is! List) return [];

      final alerts = <Alert>[];
      for (final entry in json.whereType<Map<String, dynamic>>()) {
        try {
          alerts.add(Alert.fromOrefHistory(entry));
        } catch (e) {
          // One malformed history row should not discard the whole history feed.
        }
      }
      return alerts;
    } catch (e) {
      return [];
    }
  }
}
