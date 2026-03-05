import 'dart:convert';
import '../../core/api_endpoints.dart';
import '../models/alert.dart';
import 'http_client.dart';

class OrefHistoryService {
  final HttpClient _httpClient;

  OrefHistoryService(this._httpClient);

  /// Fetch alert history.
  /// Returns a list of Alert objects from the last ~1 hour of events.
  /// Returns empty list on error.
  Future<List<Alert>> fetchAlertHistory() async {
    try {
      final body = await _httpClient.get(
        ApiEndpoints.orefHistory,
        useOrefHeaders: true,
      );
      return _parseHistoryResponse(body);
    } on HttpException {
      rethrow;
    } catch (e) {
      return [];
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

      return json
          .whereType<Map<String, dynamic>>()
          .map((entry) => Alert.fromOrefHistory(entry))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
